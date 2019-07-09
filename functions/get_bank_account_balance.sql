-- Get bank account balances
CREATE OR REPLACE FUNCTION pg_temp.Get_Bank_Account_Balance(_BankAccountID integer)
  RETURNS TABLE(BankAccountID integer, EcoSysAccount character varying, BookKeepingBalance numeric, Datestamp timestamp with time zone, BankBalance numeric, Available numeric, BalanceDatestamp timestamp with time zone)
  LANGUAGE sql IMMUTABLE
AS $function$
SELECT BankAccounts.BankAccountID,
       Accounts.Name AS EcoSysAccount,
       AccountBalancesDaily.Balance AS BookKeepingBalance,
       AccountBalancesDaily.Datestamp,
       BankaccountBalances.Balance AS BankBalance,
       BankAccountBalances.Available,
       bankaccountBalances.BalanceDatestamp
  FROM BankAccounts
  JOIN Accounts ON (BankAccounts.EcoSysAccount = Accounts.Name)
  JOIN AccountBalances ON (Accounts.AccountID = AccountBalances.AccountID)
  JOIN AccountBalancesDaily ON (AccountBalances.AccountBalanceID = AccountBalancesDaily.AccountBalanceID)
  JOIN BankAccountBalances ON (BankAccountBalances.BankAccountID = BankAccounts.BankAccountID)
 WHERE BankAccounts.BankAccountID = $1
   AND AccountBalancesDaily.Datestamp > current_date - 7
 ORDER BY AccountBalancesDaily.Datestamp DESC
 LIMIT 1
$function$;

-- Prompt variable and execute function
-- \set get_bank_account_balance '\\prompt ''Please enter BankAccountID'', bank_account_id \\\\ SELECT ':support'.Get_Bank_Account_Balance(':bank_account_id');'
