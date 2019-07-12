/* Merchant's Auto-Settlements Details and Info */

\prompt 'Please enter a Processing Account', processingaccount

\pset expanded off

WITH PARAMETERS(processingaccount) AS(
 VALUES(:'processingaccount')
 ),
 INFORMATION AS(
   SELECT Users.Username, SettlementAccounts.UserID, Currency, schedule, isodowschedule, dayofmonthschedule
     FROM Autosettle.SettlementAccounts
     JOIN Users ON Users.UserID = SettlementAccounts.userID
    WHERE Username IN (SELECT processingaccount FROM PARAMETERS)
  ),
  SETTLEMENTS AS(
    SELECT Subquery.Username, Subquery.Currency, vSettlements.BankWithdrawalID, BankWithdrawals.Datestamp AS Datestamp, to_char(BankWithdrawals.Datestamp,'day')::char AS date, vSettlements.Settlementamount, vSettlements.EndTimeStamp, LEFT(UPPER(to_char(BankWithdrawals.TimeStampExecuted,'day')),3) as executed
     FROM (SELECT Username, Currency, MAX(Datestamp) AS Datestamp
             FROM Autosettle.settlementbatches
             JOIN autosettle.settlements ON settlements.settlementbatchid = settlementbatches.settlementbatchid
             JOIN Users ON users.userid = settlementbatches.userid
            WHERE Users.Username IN (SELECT processingaccount FROM PARAMETERS)
            GROUP BY 1,2
            ORDER BY 1) AS Subquery
     JOIN (SELECT settlementbatches.settlementbatchid, users.username, settlementbatches.settlementdate, settlementbatches.currency, settlements.settlementamount, settlements.extra, settlements.bankwithdrawalid, settlementbatches.starttimestamp, settlementbatches.endtimestamp, settlementbatches.datestamp
             FROM autosettle.settlementbatches
             JOIN autosettle.settlements ON settlements.settlementbatchid = settlementbatches.settlementbatchid
             JOIN users ON users.userid = settlementbatches.userid
            WHERE Users.Username IN (SELECT processingaccount FROM PARAMETERS)) AS vSettlements ON (vSettlements.Username = Subquery.Username AND vSettlements.Datestamp = Subquery.Datestamp AND vSettlements.Currency = Subquery.Currency)
     JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID=vSettlements.BankWithdrawalID)
   ),
   BUFFER AS(
     SELECT Users.Username as username, (Autosettle.Get_Effective_Float(Users.Username, settlementaccounts.Currency)).*, FloatAdjustment.Amount AS LastAdjustmentAmount, FloatAdjustment.RecordDate As AdjustementDate
       FROM Autosettle.settlementaccounts
       JOIN users ON users.userid = settlementaccounts.userid
       LEFT JOIN (SELECT UserID, Currency, amount, recorddate::timestamp(0)
                    FROM Autosettle.FloatAdjustments
                   WHERE UserID = GET_USERID((SELECT processingaccount FROM PARAMETERS)) AND ordertype = 'FloatAdjustment' ORDER BY RecordDate DESC LIMIT 1) AS FloatAdjustment ON FloatAdjustment.UserID = SettlementAccounts.UserID AND FloatAdjustment.Currency = SettlementAccounts.Currency
      WHERE Users.Username IN (SELECT processingaccount FROM PARAMETERS)
    ),
    BALANCE AS(
      SELECT (SELECT processingaccount FROM PARAMETERS) as Username, (BALANCE((SELECT processingaccount FROM PARAMETERS))).*
    /*SELECT Users.Username,
             COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency,
             ROUND(SUM(round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),8)) over(),2) as Balance
        FROM FlagValues
       INNER JOIN FlagValueAccountingTransactions ON (FlagValueAccountingTransactions.FlagValueID = FlagValues.FlagValueID)
       INNER JOIN Events ON (Events.EventID = FlagValueAccountingTransactions.EventID)
       INNER JOIN Bindings ON (Bindings.BindID = Events.BindID)
       INNER JOIN Users ON (Users.Username = FlagValues.Value)
        LEFT JOIN Orders ON (Orders.ChainID = Events.ChainID)
        LEFT JOIN FXTrades ON (FXTrades.TransactionID = FlagValueAccountingTransactions.TransactionID)
        JOIN Settlements ON (Settlements.Username=Users.Username) AND (Settlements.Currency=COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency))
       WHERE FlagValues.FlagID = CONST_Username_FlagID()
         AND Users.UserID = Get_UserID((SELECT processingaccount FROM PARAMETERS))
         AND (COALESCE(FXTrades.NewCurrency,FlagValueAccountingTransactions.Currency) = ANY('{SETTLEMENTS.Currency}'::text[]))
         AND FlagValueAccountingTransactions.RecordDate >= SETTLEMENTS.datestamp::date + '2 hours'::interval
         AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
         AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
       ORDER BY FlagValueAccountingTransactions.RecordDate ASC*/
     ),
     ERRORLOG AS(
       SELECT Autosettle.Log.UserID, Autosettle.Log.Currency, Autosettle.Log.Datestamp, replace(Autosettle.Log.Message,'transactions of ','') || ' ' || '('||Autosettle.Log.Datestamp::date||')' as message
         FROM (SELECT UserID, Currency, MAX(Datestamp) AS Datestamp
                 FROM Autosettle.Log
                GROUP BY 1,2
                ORDER BY 1) AS LogQuery
         JOIN Autosettle.Log ON (Autosettle.Log.UserID = LogQuery.UserID) AND (Autosettle.Log.Currency = LogQuery.Currency)
        WHERE Autosettle.Log.Datestamp = LogQuery.Datestamp
          AND Autosettle.Log.UserID = GET_USERID((SELECT processingaccount FROM PARAMETERS))
        ),
        RETURNED AS(
          SELECT Users.UserID, Users.Username, Settlements.BankWithdrawalID, BankWithdrawals.MessageID, BankWithdrawals.Datestamp::timestamp(0), BankWithdrawals.TimestampExecuted::timestamp(0), BankWithdrawalStates.BankWithdrawalState,
                 Settlements.SettlementCurrency, Settlements.SettlementAmount,
                 FloatAdjustments.ReturnedBankWithdrawalID,
                 FloatAdjustments.AdjustedBy,
                 FloatAdjustments.RecordDate::timestamp(0),
                 sum(Settlements.SettlementAmount) OVER ()
            FROM autosettle.Settlements
            JOIN autosettle.SettlementAccounts ON (SettlementAccounts.SettlementAccountID = Settlements.SettlementAccountID)
            JOIN Users ON (Users.UserID = SettlementAccounts.UserID)
            JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID = Settlements.BankWithdrawalID)
            JOIN BankWithdrawalStates ON (BankWithdrawalStates.BankWithdrawalStateID = BankWithdrawals.BankWithdrawalStateID)
            LEFT JOIN autosettle.FloatAdjustments ON (FloatAdjustments.ReturnedBankWithdrawalID = Settlements.BankWithdrawalID)
           WHERE BankWithdrawals.BankWithdrawalStateID = ANY('{2,13}'::integer[])
             AND Users.UserID = GET_USERID((SELECT processingaccount FROM PARAMETERS))
             AND FloatAdjustments.ReturnedBankWithdrawalID IS NULL
           ORDER BY BankWithdrawals.Datestamp ASC
         )
         SELECT INFORMATION.Username,
                INFORMATION.Currency as Currency,
                COALESCE((CASE WHEN INFORMATION.isodowschedule = '{2,4}' THEN 'TUE & THU'
                               WHEN INFORMATION.isodowschedule = '{1,3}' THEN 'MON & WED'
                               WHEN INFORMATION.isodowschedule = '{1,4}' THEN 'MON & THU'
                               WHEN INFORMATION.isodowschedule = '{1,2,3,4,5}' THEN 'MON to FRI'
                               WHEN INFORMATION.isodowschedule = '{1}' then 'MON'
                               WHEN INFORMATION.isodowschedule = '{2}' then 'TUE'
                               WHEN INFORMATION.isodowschedule = '{3}' then 'WED'
                               WHEN INFORMATION.isodowschedule = '{4}' then 'THU'
                               WHEN INFORMATION.isodowschedule = '{5}' then 'FRI'
                               ELSE NULL END), INFORMATION.Schedule) as Schedule,
                Settlements.Datestamp::timestamp(0) AS LastSettlementDate,
                Settlements.BankWithdrawalID AS LastBankWithdrawalID,
                Settlements.SettlementAmount AS LastSettlementAmount,
                Buffer.Fundings AS Float_Fundings, Buffer.Adjustments AS Float_adjustments, Buffer.ManualSettlements AS Manual_Settlements, Buffer.Total AS Float_Total, Buffer.LastAdjustmentAmount, Buffer.AdjustementDate,
                (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) as Balance,
                (CASE WHEN INFORMATION.Schedule = 'daily' AND Settlements.datestamp >=now()-'24 hours'::interval then 'DONE'
                      WHEN INFORMATION.Schedule = 'monthly' AND Settlements.datestamp >=now()-'31 days'::interval then 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{2,4}' AND Settlements.Executed IN ('TUE','THU') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{1,3}' AND Settlements.Executed IN ('MON','WED') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{1,4}' AND Settlements.Executed IN ('MON','THU') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{1,2,3,4,5}' AND Settlements.Executed IN ('MON','TUE','WED','THU','FRI') AND Settlements.datestamp >=now()-'3 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{1}' AND Settlements.Executed IN ('MON') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{2}' AND Settlements.Executed IN ('TUE') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{3}' AND Settlements.Executed IN ('WED') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{4}' AND Settlements.Executed IN ('THU') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN INFORMATION.Schedule = 'isodow' AND INFORMATION.isodowschedule = '{5}' AND Settlements.Executed IN ('FRI') AND Settlements.datestamp >=now()-'7 days'::interval THEN 'DONE'
                      WHEN Settlements.SettlementAmount IS NULL AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) IN (0.00,0) THEN 'NO FUNDS'
                      WHEN Settlements.Datestamp::timestamp(0) < '2018-01-01' THEN 'NO RECENT'
                      WHEN INFORMATION.Schedule = 'monthly' AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) IN (0.00,0) AND Settlements.Datestamp <= now()-'31 days'::interval THEN 'NO FUNDS'
                      WHEN INFORMATION.Schedule != 'monthly' AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) IN (0.00,0) AND Settlements.Datestamp <=now()-'24 hours'::interval THEN 'NO FUNDS'
                      WHEN (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Total)) OR (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Fundings)) OR (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Adjustments)) THEN 'NO FUNDS'
                      ELSE 'NO SETTLEMENT' end) as Status,
                (CASE WHEN Errorlog.Datestamp < Settlements.Datestamp THEN NULL
                      WHEN Errorlog.Message IS NULL THEN '***Balance probably acquired after latest Auto-Settle Due date/time' ELSE ErrorLog.Message END) as Error_Message_Log,
                (CASE WHEN Returned.BankWithdrawalID IS NOT NULL THEN 'TRUE' ELSE 'FALSE' END) as ReturnedWithdrawal
           FROM INFORMATION
           LEFT JOIN Settlements ON (Settlements.Username=INFORMATION.Username) AND (Settlements.Currency=INFORMATION.Currency)
           LEFT JOIN Balance ON (Balance.Username=INFORMATION.Username) AND (Balance.Currency=INFORMATION.Currency)
           LEFT JOIN Buffer ON (Buffer.Username=INFORMATION.Username) AND (Buffer.Currency=INFORMATION.Currency)
           LEFT JOIN ErrorLog ON (ErrorLog.UserID = INFORMATION.UserID) AND (ErrorLog.Currency = INFORMATION.Currency)
           LEFT JOIN Returned ON (Returned.UserID = INFORMATION.UserID) AND (Returned.SettlementCurrency = INFORMATION.Currency)
           JOIN Users ON (Users.UserID = INFORMATION.UserID)
          GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16
;
