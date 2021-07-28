/* To Determine PENDING/EXECUTING Withdrawals Auto_Retry_Pending_Payments (cron) Will Retry*/

--Cron will retry PENDING & EXECUTING withdrawals WHERE
--Limit not exceeded (SUM & COUNT)
--Datestamp within one week and initiated more than 14 mins ago
--TimestampExecutingUnfinished
--Have not been retried already
--All Accounts besides OKOY, UBRT & SWED initiated less than 30 mins ago
--Trust not executed is TRUE

\set QUIET ON

\pset expanded off

SELECT BankWithdrawals.BankWithdrawalID,  BankAccounts.EcoSysAccount, BankWithdrawals.Amount, BankWithdrawals.Currency, BankWithdrawalStates.BankWithdrawalState, BankWithdrawals.Datestamp::timestamp(0), BankWithdrawals.Modificationdate::timestamp(0), (Should_Trust_Not_Executed(BankWithdrawals.BankWithdrawalID)).TrustNotExecuted, (CASE WHEN BankWithdrawals.BankWithdrawalID IN (SELECT BankWithdrawalID from StalledBankWithdrawals) THEN 't' ELSE 'f' END) AS Unstalled,
       (SELECT sum(round(sum(FX_ReadOnly(View_Stalled_Bank_Withdrawals.Currency, 'SEK') * Amount), 2)) OVER () FROM View_Stalled_Bank_Withdrawals WHERE StalledState = 'PENDING' AND StalledDatestamp > now()-'24 hours'::interval) AS LimitSum,
       (SELECT sum(count(*)) OVER () FROM View_Stalled_Bank_Withdrawals WHERE StalledState = 'PENDING' AND StalledDatestamp > now()-'24 hours'::interval) AS LimitCount
  FROM BankWithdrawals
  JOIN BankAccounts ON BankAccounts.BankAccountID = BankWithdrawals.SendingBankAccountID
 INNER JOIN BankWithdrawalStates ON (BankWithdrawalStates.BankWithdrawalStateID = BankWithdrawals.BankWithdrawalStateID)
 WHERE BankWithdrawals.ModificationDate BETWEEN now()-'7 days'::interval AND now()-'14 minutes'::interval
   AND (
        BankWithdrawals.BankWithdrawalStateID = 11 /* PENDING */
        OR
        (BankWithdrawals.BankWithdrawalStateID = 5 /* EXECUTING */ AND BankWithdrawals.TimestampExecutingUnfinished IS NOT NULL)
      )
   AND NOT EXISTS (SELECT 1 FROM StalledBankWithdrawals WHERE StalledBankWithdrawals.BankWithdrawalID = BankWithdrawals.BankWithdrawalID)
   AND BankAccounts.EcosysAccount NOT LIKE 'CLIENT_FUNDS_FINLAND_OKOY%'
   AND BankAccounts.EcosysAccount NOT LIKE 'CLIENT_FUNDS_HUNGARY_UBRT%'
   AND BankAccounts.EcosysAccount NOT LIKE 'CLIENT_FUNDS_SWEDEN_NDEA%'
   AND (
        BankAccounts.EcosysAccount NOT LIKE 'CLIENT_FUNDS_SWEDEN_SWED%'
        OR
        BankWithdrawals.ModificationDate < now()-'30 minutes'::interval --Excluding all within last 30 minutes
      )
   AND (Should_Trust_Not_Executed(BankWithdrawals.BankWithdrawalID)).TrustNotExecuted
   AND ((
         SELECT sum(round(sum(FX_ReadOnly(View_Stalled_Bank_Withdrawals.Currency, 'SEK') * Amount), 2)) OVER ()
           FROM View_Stalled_Bank_Withdrawals
          WHERE StalledState = 'PENDING'
            AND StalledDatestamp > now()-'24 hours'::interval
          ) < 500000
       AND
        (
         SELECT sum(count(*)) OVER ()
           FROM View_Stalled_Bank_Withdrawals
          WHERE StalledState = 'PENDING'
            AND StalledDatestamp > now()-'24 hours'::interval
          ) < 400
       )
    --AND BankAccounts.Ecosysaccount = 'CLIENT_FUNDS_SWEDEN_SWED'
 ORDER BY Datestamp ASC
      ;

\echo "Best to be run after :check_safe_to_retry"
