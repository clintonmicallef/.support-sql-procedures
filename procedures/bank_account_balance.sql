/*Balance of one of Trustly's Bank Accounts*/

\prompt 'Please enter a BankAccountID', bankaccountID

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

/* Make use of temporary functions
SELECT :support.Get_Bank_Account_Balance(:bankaccountID);
*
