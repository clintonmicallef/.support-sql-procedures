/* Show bank account balances */

\prompt 'Please enter a BankAccountID', bankaccountID

\set QUIET ON

\pset expanded on

SELECT Bankaccounts.BankAccountID, Accounts.name, Accountbalancesdaily.balance AS bookkeepingbalance, accountbalancesdaily.datestamp::timestamp(0),
       Bankaccountbalances.balance AS bankbalance, bankaccountbalances.available, bankaccountbalances.balancedatestamp::timestamp(0)
  FROM bankaccounts
  JOIN accounts ON (bankaccounts.ecosysaccount = accounts.name)
  JOIN accountbalances ON (accounts.accountid = accountbalances.accountid)
  JOIN accountbalancesdaily ON (accountbalances.accountbalanceid = accountbalancesdaily.accountbalanceid)
  JOIN bankaccountbalances ON (bankaccountbalances.BankAccountID = bankaccounts.BankAccountID)
 WHERE bankaccounts.BankAccountID = :'bankaccountID' -- change bankaccountID
   AND accountbalancesdaily.datestamp > current_date - 5 -- change interval
 ORDER BY datestamp DESC
 LIMIT 1;


 -- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
 SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'bank_account_balance');
 \i '~/.support-sql-procedures/userlogsetup.psql'

/* Make use of temporary functions
SELECT :support.Get_Bank_Account_Balance(:bankaccountID);
*/
