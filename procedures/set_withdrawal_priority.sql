/*FUNCTION sets retrynow with Parameters: EcoSysAccount, ProcessingAccount, Delay and/or enduser's Receiving Bank
  Allows user to specify the processing account or leave as NULL
  Allows user to speicify the delay of a payout or leave as NULL
  Allows user to specify the receiving bank or  leave as NULL*/

\prompt 'Please enter an EcoSysAccount', ecosysaccount
\prompt 'Please enter a Processing Account or press enter to continue', processingaccount
\prompt 'Please enter a delay (including unit of time example: 30 mins) or press enter to continue', delay
\prompt 'Please enter a receiving bank or press enter to continue', tobank

\pset expanded off

WITH RETRY AS(
  SELECT View_All_Bank_Withdrawals.EcoSysAccount, View_All_Bank_Withdrawals.Username, View_All_Bank_Withdrawals.BankWithdrawalID, View_All_Bank_Withdrawals.Amount, View_All_Bank_Withdrawals.ToBank, View_All_Bank_Withdrawals.BankWithdrawalType, (now()-View_All_Bank_Withdrawals.Datestamp) AS Delay
    FROM View_All_Bank_Withdrawals
    JOIN BankWithdrawals ON BankWithdrawals.BankWithdrawalID = View_All_Bank_Withdrawals.BankWithdrawalID
   WHERE View_All_Bank_Withdrawals.EcoSysAccount = :'ecosysaccount'
     AND View_All_Bank_Withdrawals.BankWithdrawalState = 'QUEUED'
     AND View_All_Bank_Withdrawals.BankWithdrawalType IN ('EXPRESS')
     AND View_All_Bank_Withdrawals.Datestamp >= now() - '4 days'::interval
     --AND now() - View_All_Bank_Withdrawals.Datestamp >= :'delay'::interval --DELAY
     AND (SELECT CASE WHEN NULLIF(:'delay','') IS NOT NULL THEN now() - View_All_Bank_Withdrawals.Datestamp >= :'delay'::interval ELSE 'TRUE' END)
     AND BankWithdrawals.retrynow IS NULL
     AND BankWithdrawals.Attempts = 1
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Username = :'processingaccount' ELSE 'TRUE' END)
     AND (SELECT CASE WHEN NULLIF(:'tobank','') IS NOT NULL THEN View_All_Bank_Withdrawals.toBank = :'tobank' ELSE 'TRUE' END)
   ORDER BY View_All_Bank_Withdrawals.bankwithdrawaltype, View_All_Bank_Withdrawals.Datestamp DESC
)
SELECT retry_queued_bank_withdrawal(Retry.BankWithdrawalID) FROM Retry;
