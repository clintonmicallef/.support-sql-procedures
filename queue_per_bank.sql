/*Queue of a specific EcoSysAccount*/

\prompt 'Please enter an EcoSysAccount', ecosysaccount

\pset expanded off

SELECT ROW_NUMBER() OVER(ORDER BY b.Attempts, t.Priority DESC, b.Datestamp),
       v.BankWithdrawalID,v.Username,v.BankWithdrawalState,v.BankWIthdrawalType,v.Amount,v.Currency,v.Datestamp,b.modificationdate,v.ToBank,v.ToClearingHouse,b.Attempts,b.RetryNow,t.Priority,
       --v.ToAccountNumber,
       (now() - b.Datestamp)::interval(0) AS Delay,
       SUM(b.Amount) OVER()
  FROM View_All_Bank_Withdrawals v
  JOIN BankWithdrawals b ON (b.BankWithdrawalID = v.BankWithdrawalID)
  JOIN Users ON Users.UserID = b.UserID
  JOIN BankWithdrawalTypes t ON (b.BankWithdrawalTypeID = t.BankWithdrawalTypeID)
 WHERE EcoSysAccount IN (:'ecosysaccount')
   AND BankWithdrawalState = 'QUEUED'
   AND v.Datestamp >=now()-'7 days'::interval
 ORDER BY v.BankWithdrawalType, v.Datestamp DESC, b.Attempts, t.Priority DESC;
