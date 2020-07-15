/* Check active withdrawal queues */

\set QUIET ON

\pset expanded off

SELECT BankWithdrawals.SendingBankAccountID,
       View_Bank_Withdrawals_In_Queue.EcoSysAccount,
       BankWithdrawalTypes.BankWithdrawalType AS Type,
       BankWithdrawalStates.BankWithdrawalState AS State,
       BankWithdrawals.Currency,
       --array_agg(DISTINCT UserCategories.Name) AS UserCategories, --another perhaps irrelevant attribute
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
 --WHERE View_Bank_Withdrawals_In_Queue.Enabled IS TRUE --Do we need this?
 GROUP BY 1, 2, 3, 4, 5
 ORDER BY count(*) DESC;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'check_queue');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
