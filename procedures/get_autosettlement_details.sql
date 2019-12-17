/* Merchant's Auto-Settlements Details and Info */

\prompt 'Please enter a Processing Account', processingaccount

\set QUIET ON

\pset expanded off

\echo '\n'
\echo '***NOTE***'
\echo 'Check whether merchant\'s balance at the time of the Settlement covers the Settlement Amount WITH Fee!'
\echo '\n'

WITH PARAMETERS(processingaccount) AS(
 VALUES(:'processingaccount')
 ),
 INFORMATION AS(
   SELECT Users.Username, SettlementAccounts.UserID, Currency, schedule, isodowschedule, dayofmonthschedule, lastsettlementattempt
     FROM Autosettle.SettlementAccounts
     JOIN Users ON Users.UserID = SettlementAccounts.userID
    WHERE Username IN (SELECT processingaccount FROM PARAMETERS)
  ),
  SETTLEMENTS AS(
    SELECT Subquery.Username, Subquery.Currency, vSettlements.SettlementDate, vSettlements.StartTimestamp, vSettlements.Endtimestamp, vSettlements.BankWithdrawalID, vSettlements.BankWithdrawalError, BankWithdrawals.Datestamp AS Datestamp, to_char(BankWithdrawals.Datestamp,'day')::char AS date, vSettlements.Settlementamount, LEFT(UPPER(to_char(BankWithdrawals.TimeStampExecuted,'day')),3) AS executed, bankwithdrawals.timestampexecuted
     FROM (SELECT Username, Currency, MAX(Datestamp) AS Datestamp
             FROM Autosettle.settlementbatches
             JOIN autosettle.settlements ON settlements.settlementbatchid = settlementbatches.settlementbatchid
             JOIN Users ON users.userid = settlementbatches.userid
            WHERE Users.Username IN (SELECT processingaccount FROM Parameters)
            GROUP BY 1,2
            ORDER BY 1) AS Subquery
     JOIN (SELECT settlementbatches.settlementbatchid, users.username, settlementbatches.settlementdate, settlementbatches.currency, settlements.settlementamount, settlements.extra, settlements.bankwithdrawalid, settlementbatches.starttimestamp, settlementbatches.endtimestamp, settlementbatches.datestamp, settlements.bankwithdrawalerror
             FROM autosettle.settlementbatches
             JOIN autosettle.settlements ON settlements.settlementbatchid = settlementbatches.settlementbatchid
             JOIN users ON users.userid = settlementbatches.userid
            WHERE Users.Username IN (SELECT processingaccount FROM Parameters)) AS vSettlements ON (vSettlements.Username = Subquery.Username AND vSettlements.Datestamp = Subquery.Datestamp AND vSettlements.Currency = Subquery.Currency)
     JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID=vSettlements.BankWithdrawalID)
   ),
   BUFFER AS(
     SELECT Users.Username AS username, (Autosettle.Get_Effective_Float(Users.Username, settlementaccounts.Currency)).*, FloatAdjustment.Amount AS LastAdjustmentAmount, FloatAdjustment.RecordDate As AdjustementDate
       FROM Autosettle.settlementaccounts
       JOIN users ON users.userid = settlementaccounts.userid
       LEFT JOIN LATERAL (
         SELECT UserID, Currency, amount, recorddate::timestamp(0)
           FROM Autosettle.FloatAdjustments
          WHERE UserID = GET_USERID((SELECT processingaccount FROM PARAMETERS))
            AND ordertype = 'FloatAdjustment'
          ORDER BY RecordDate DESC LIMIT 1
        ) AS FloatAdjustment ON FloatAdjustment.UserID = SettlementAccounts.UserID AND FloatAdjustment.Currency = SettlementAccounts.Currency
      WHERE Users.Username IN (SELECT processingaccount FROM PARAMETERS)
    ),
    BALANCE AS(
      SELECT (SELECT processingaccount FROM PARAMETERS) AS Username, (BALANCE((SELECT processingaccount FROM PARAMETERS))).*
     ),
     BALANCEMAXDATE AS(
       SELECT (SELECT processingaccount FROM PARAMETERS) AS Username,
              COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency,
              MAX(FlagValueAccountingTransactions.RecordDate)
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
          AND FlagValueAccountingTransactions.RecordDate >= now() - interval '1 month'
          AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
          AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
        GROUP BY 1,2
      ),
      ERRORLOG AS(
        SELECT Autosettle.Log.UserID, Autosettle.Log.Currency, Autosettle.Log.Datestamp, replace(Autosettle.Log.Message,'transactions of ','') || ' ' || '('||Autosettle.Log.Datestamp::timestamp(0)||')' AS message
          FROM (SELECT UserID, Currency, MAX(Datestamp) AS Datestamp
                  FROM Autosettle.Log
                 GROUP BY 1,2
                 ORDER BY 1) AS LogQuery
          JOIN Autosettle.Log ON (Autosettle.Log.UserID = LogQuery.UserID) AND (Autosettle.Log.Currency = LogQuery.Currency)
         WHERE Autosettle.Log.Datestamp = LogQuery.Datestamp
           AND Autosettle.Log.UserID = GET_USERID((SELECT processingaccount FROM PARAMETERS))
         ),
         NextAutosettlementAmount AS(
           SELECT DISTINCT
                  (SELECT processingaccount FROM PARAMETERS) AS Username,
                  COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency,
                  ROUND(SUM(round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),8)) over(PARTITION BY COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency)),2) as Total
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
              AND FlagValueAccountingTransactions.RecordDate >= Settlements.starttimestamp::timestamp(0) + interval '1 day'
              AND FlagValueAccountingTransactions.RecordDate <= Settlements.endtimestamp::timestamp(0) + interval '1 day'
              AND  Get_MessageID_By_EventID(Events.EventID) NOT LIKE 'Automatic%'
              AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
              AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
            ),
            FEEs AS(
              SELECT userid,
                     REPLACE(SUBSTRING(SUBSTRING(debitfunctionparams::text, '=(.*)'), '=(.*)/'),'"','') AS Currency,
                     REPLACE(SUBSTRING(debitfunctionparams::text, '=(.*) '),'"','') AS FeeAmount,
                     REPLACE(SUBSTRING(SUBSTRING(debitfunctionparams::text, '=(.*)'), '=(.*)/'),'"','') || ' ' ||  REPLACE(SUBSTRING(debitfunctionparams::text, '=(.*) '),'"','') AS Fee_Currency
                FROM DebitModels
               WHERE UserID = GET_USERID((SELECT processingaccount FROM Parameters))
                 AND paymenttypeid = 5 --SETTLEMENT
               ORDER BY Datestamp DESC LIMIT 1
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
                     INFORMATION.Currency AS Currency,
                     COALESCE((CASE WHEN INFORMATION.isodowschedule = '{2,4}' THEN 'TUE & THU'
                                    WHEN INFORMATION.isodowschedule = '{1,3}' THEN 'MON & WED'
                                    WHEN INFORMATION.isodowschedule = '{1,4}' THEN 'MON & THU'
                                    WHEN INFORMATION.isodowschedule = '{1,2,3,4,5}' THEN 'MON to FRI'
                                    WHEN INFORMATION.isodowschedule = '{1}' then 'MON'
                                    WHEN INFORMATION.isodowschedule = '{2}' then 'TUE'
                                    WHEN INFORMATION.isodowschedule = '{3}' then 'WED'
                                    WHEN INFORMATION.isodowschedule = '{4}' then 'THU'
                                    WHEN INFORMATION.isodowschedule = '{5}' then 'FRI'
                                    ELSE NULL END), INFORMATION.Schedule) AS Schedule,
                     Settlements.StartTimestamp::timestamp(0),
                     Settlements.EndTimeStamp::timestamp(0),
                     Information.lastsettlementattempt,
                     Settlements.SettlementDate AS LastSettlementDate,
                     Settlements.SettlementAmount,
                     Fees.Fee_currency AS FeeAmount,
                     Settlements.BankWithdrawalID,
                     COALESCE((Settlements.TimestampExecuted::timestamp(0))::text, Settlements.BankWithdrawalError) AS "Executed/Error",
                     COALESCE((CASE WHEN NextAutosettlementAmount.Total < 0 THEN NULL ELSE NextAutosettlementAmount.Total END), (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) AS NextSettlementAmount,
                     /*Buffer.ManualSettlements AS Manual_Settlements,*/ Buffer.AdjustementDate::timestamp(0), Buffer.LastAdjustmentAmount AS LastAdjustment, Buffer.Total AS FloatTotal, --Buffer.LastAdjustmentAmount, Buffer.AdjustementDate::date,
                     (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) AS Balance,
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
                           WHEN Settlements.Datestamp::timestamp(0) < now()  - interval '1 year' THEN 'NO RECENT'
                           WHEN INFORMATION.Schedule = 'monthly' AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) IN (0.00,0) AND Settlements.Datestamp <= now()-'31 days'::interval THEN 'NO FUNDS'
                           WHEN INFORMATION.Schedule != 'monthly' AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) IN (0.00,0) AND Settlements.Datestamp <=now()-'24 hours'::interval THEN 'NO FUNDS'
                           WHEN (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Total)) OR (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Fundings)) OR (FLOOR((CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END)) <= FLOOR(Buffer.Adjustments)) THEN 'NO FUNDS'
                           ELSE 'NO SETTLEMENT' end) AS Status,
                     (CASE WHEN (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) > 0 AND (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) <= Buffer.Total
                           THEN 'Balance less than Float amount, will only settle amount above float'
                           WHEN (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) > 0
                                AND
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
                                      ELSE 'NO SETTLEMENT' end) = 'NO SETTLEMENT'
                                AND (BALANCEMAXDATE.max::date = current_date)
                           THEN 'No Funds to settle during previous settlement batch. Balance acquired today, should settle through next scheduled settlement'
                           WHEN (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) > 0
                                AND
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
                                      ELSE 'NO SETTLEMENT' end) = 'DONE'
                                AND BALANCEMAXDATE.max::date = current_date
                           THEN 'Last Settlement DONE. Balance acquired today, should settle through next scheduled settlement'
                           WHEN (CASE WHEN Balance.Balance IS NULL THEN 0.00::int ELSE Balance.Balance END) > 0
                                AND BALANCEMAXDATE.max::date < current_date
                           THEN 'Error, funds did not settle'
                           WHEN Errorlog.Datestamp < Settlements.Datestamp
                           THEN NULL
                           ELSE ErrorLog.Message END) AS Message_Log,
                     (CASE WHEN Returned.BankWithdrawalID IS NOT NULL THEN 'TRUE' ELSE 'FALSE' END) AS Returned
                FROM INFORMATION
                LEFT JOIN Settlements ON (Settlements.Username=INFORMATION.Username) AND (Settlements.Currency=INFORMATION.Currency)
                LEFT JOIN Balance ON (Balance.Username=INFORMATION.Username) AND (Balance.Currency=INFORMATION.Currency)
                LEFT JOIN BALANCEMAXDATE ON (BALANCEMAXDATE.Username=INFORMATION.Username) AND (BALANCEMAXDATE.Currency=INFORMATION.Currency)
                LEFT JOIN Buffer ON (Buffer.Username=INFORMATION.Username) AND (Buffer.Currency=INFORMATION.Currency)
                LEFT JOIN ErrorLog ON (ErrorLog.UserID = INFORMATION.UserID) AND (ErrorLog.Currency = INFORMATION.Currency)
                LEFT JOIN NextAutosettlementAmount ON (NextAutosettlementAmount.Username=INFORMATION.Username) AND (NextAutosettlementAmount.Currency=INFORMATION.Currency)
                --LEFT JOIN BankWithdrawalInfo ON (BankWithdrawalInfo.UserID = INFORMATION.UserID) AND (BankWithdrawalInfo.SettlementCurrency = INFORMATION.Currency)
                LEFT JOIN Returned ON (Returned.UserID = INFORMATION.UserID) AND (Returned.SettlementCurrency = INFORMATION.Currency)
                LEFT JOIN Fees ON (Fees.UserID = INFORMATION.UserID)
                JOIN Users ON (Users.UserID = INFORMATION.UserID)
;


INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'check_queue.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
