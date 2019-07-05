-- Check active withdrawal queues
\set QUIET ON
\pset expanded off

SELECT BankWithdrawals.SendingBankAccountID,
       View_Bank_Withdrawals_In_Queue.EcoSysAccount,
       BankWithdrawalTypes.BankWithdrawalType AS Type,
       BankWithdrawalStates.BankWithdrawalState AS State,
       BankWithdrawals.Currency,
       array_agg(DISTINCT UserCategories.Name) AS UserCategories,
       count(*),
       sum(BankWithdrawals.Amount),
       max(now() - BankWithdrawals.Datestamp)::interval(0) AS MaxDelay,
       avg(now() - BankWithdrawals.Datestamp)::interval(0) AS AvgDelay,
       floor(avg(BankWithdrawals.Attempts)) AS AvgAttempts,
       (SELECT max(ExecutedBankWithdrawals.TimestampExecuted)::timestamp(0)
          FROM BankWithdrawals AS ExecutedBankWithdrawals
         WHERE ExecutedBankWithdrawals.SendingBankAccountID = BankWithdrawals.SendingBankAccountID
       ) AS LastExecutedAt
  FROM View_Bank_Withdrawals_In_Queue
  JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID = View_Bank_Withdrawals_In_Queue.BankWithdrawalID)
  JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
  JOIN BankWithdrawalStates ON (BankWithdrawalStates.BankWithdrawalStateID = BankWithdrawals.BankWithdrawalStateID)
  JOIN Users ON (Users.UserID = BankWithdrawals.UserID)
  JOIN UserCategories ON (UserCategories.UserCategoryID = Users.UserCategoryID)
 WHERE View_Bank_Withdrawals_In_Queue.Enabled IS TRUE
 GROUP BY 1, 2, 3, 4, 5
 ORDER BY count(*) DESC;
