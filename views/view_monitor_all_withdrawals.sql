CREATE TEMPORARY VIEW View_Monitor_All_Withdrawals AS (
  SELECT BankAccounts.BankAccountID,
         BankAccounts.EcoSysAccount,
         JWOWWInstances.NoOfInstances AS NoOfJWOWWs,
         JWOWWInstances.Crashed AS CrashedJWOWWs,
         JWOWWInstances.LastExecute,
         JWOWWInstances.StatusTimestamp,
         JWOWWInstances.LastLedger,
         MIN(BankWithdrawals.datestamp)::timestamp(0),
         MAX(BankWithdrawals.datestamp)::timestamp(0),
         BankWithdrawals.Currency,
         BankWithdrawalStates.BankWithdrawalState,
         count(*),
         Delays.MAXDELAY AS MaxDelay_EXPRESS,
         Delays.Count AS Delayed,
         COALESCE(BankAccountBalances.Available,BankAccountBalances.Balance) AS BankBalance,
         IncomingFundings.Sum AS IncomingFundings,
         sum(sum(BankWithdrawals.Amount)) OVER(PARTITION BY BankAccounts.BankAccountID) AS ReqBalance,
         sum(BankWithdrawals.Amount) AS Sum,
         (CASE WHEN Delays.MAXDELAY IS NOT NULL AND Delays.MAXDELAY > '15 MINS'::interval THEN 'DELAY!' ELSE NULL END) AS Alert
    FROM BankWithdrawals
    JOIN BankWithdrawalStates ON (BankWithdrawalStates.BankWithdrawalStateID = BankWithdrawals.BankWithdrawalStateID)
    JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
    JOIN BankAccounts ON (BankAccounts.BankAccountID = BankWithdrawals.SendingBankAccountID)
    LEFT JOIN BankAccountBalances ON (BankAccountBalances.BankAccountID = BankAccounts.BankAccountID)
    LEFT JOIN ( SELECT InternalTransfers.ToBankAccountID,
                       InternalTransfers.Currency,
                       sum(InternalTransfers.Amount)
                  FROM InternalTransfers
                  JOIN BankAccounts FromBankAccounts ON (FromBankAccounts.BankAccountID = InternalTransfers.FromBankAccountID)
                  JOIN BankAccounts ToBankAccounts ON (ToBankAccounts.BankAccountID = InternalTransfers.ToBankAccountID)
                  LEFT JOIN BankNumbers FromBankNumbers ON (FromBankNumbers.BankNumberID = FromBankAccounts.BankNumberID)
                  LEFT JOIN BankNumbers ToBankNumbers ON (ToBankNumbers.BankNumberID = ToBankAccounts.BankNumberID)
                 WHERE (InternalTransfers.Executed >= current_date - 4)
                   AND InternalTransfers.Settled IS NULL
                 GROUP BY 1,2
    ) AS IncomingFundings ON (IncomingFundings.ToBankAccountID = BankAccounts.BankAccountID)
    LEFT JOIN ( SELECT BankWithdrawals.SendingBankAccountID,
                       array_agg(DISTINCT BankIOHeartBeat.ID) AS IDs,
                       count(DISTINCT BankIOHeartBeat.ID) AS NoOfInstances,
                       array_agg(DISTINCT CASE WHEN BankIOHeartBeat.Status = 'CRASHED' THEN 'CRASHED' ELSE 'RUNNING' END) AS Statuses,
                       string_agg(DISTINCT CASE WHEN BankIOHeartBeat.Status = 'CRASHED' THEN BankIOHeartBeat.ID ELSE NULL END,',') AS Crashed,
                       count(*),
                       max(BankWithdrawals.TimestampExecuted)::timestamp(0) AS LastExecute,
                       max(BankIOHeartBeat.LastLedger)::timestamp(0) AS LastLedger,
                       max(BankIOHeartBeat.StatusTimestamp)::timestamp(0) AS StatusTimestamp
                  FROM BankWithdrawals
                  JOIN BankIOHeartBeat ON (BankIOHeartBeat.ID = (BankWithdrawals.ProcessedBy::json->>'ID'))
                 WHERE BankWithdrawals.TimestampExecuted >= now() - '96 hours'::interval
                 GROUP BY 1
                 ORDER BY count(*) DESC
    ) AS JWOWWInstances ON (JWOWWInstances.SendingBankAccountID = BankAccounts.BankAccountID)
    LEFT JOIN LATERAL (
      SELECT SendingBankAccountid, (now() - min(BankWithdrawals.Datestamp))::interval(0) AS MAXDELAY,
             COUNT(CASE WHEN (now() - (BankWithdrawals.Datestamp))::interval(0) > '15 mins'::interval THEN 1 ELSE NULL END)
        FROM BankWIthdrawals
       WHERE BankWithdrawalStateID = 1 --QUEUED
         AND BankWithdrawalTypeID = 3 --EXPRESS
         AND Datestamp >=now()-'7 days'::interval
       GROUP BY 1
    ) AS Delays ON Delays.SendingBankAccountId = BankWithdrawals.SendingBankAccountID
   WHERE BankWithdrawals.Datestamp >= current_date - '1 weeks'::interval
     AND BankWithdrawals.TimestampExecuted IS NULL
     AND BankWithdrawals.BankWithdrawalStateID <> ALL (ARRAY[2, 8, 12, 13])
     AND BankWithdrawals.SendingBankAccountID <> ALL (ARRAY[189, 337, 184]) -- CLIENT_FUNDS_PAYPAL_PPLX
     AND NOT EXISTS ( SELECT 1
                        FROM BlackListedBankAccounts
                       WHERE BlackListedBankAccounts.UserID = BankWithdrawals.UserID
                         AND BlackListedBankAccounts.ClearingHouseID = BankWithdrawals.ToClearingHouseID
                         AND BlackListedBankAccounts.ToBankNumber = BankWithdrawals.ToBankNumber
                         AND BlackListedBankAccounts.ToAccountNumber = BankWithdrawals.ToAccountNumber
                    )
   GROUP BY 1, 2, 3, 4, 5, 6, 7, 10, 11, 13, 14, 15, 16, 19
   ORDER BY BankWithdrawalState DESC, count(*) DESC
);

-- Prompt variable and execute view
-- \set monitor_all_withdrawals 'SELECT * FROM ':support'.View_Monitor_All_Withdrawals;'
