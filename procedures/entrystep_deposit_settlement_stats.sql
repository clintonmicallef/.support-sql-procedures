/* Statistical information on deposit settlement times for an entrystep */

\prompt 'Please enter an EntrystepID', entrystepID

\pset expanded off

 SELECT EventNameChainBalances.EntryStepID,
        BankAccounts.EcoSysAccount,
        min(Transfers.TriggeredSettle - Transfers.Datestamp)::interval(0) AS MinTimeToSettle,
        max(Transfers.TriggeredSettle - Transfers.Datestamp)::interval(0) AS MaxTimeToSettle,
        avg(Transfers.TriggeredSettle - Transfers.Datestamp)::interval(0) AS AvgTimeToSettle
   FROM EventNameChainBalances
   JOIN Transfers ON (Transfers.EventNameChainBalanceID = EventNameChainBalances.EventNameChainBalanceID) AND (Transfers.TransferTypeID = 1)--DEPOSIT
   JOIN BankAccounts ON (BankAccounts.TransferBankAccountID = EventNameChainBalances.ToTransferBankAccountID AND BankAccounts.Currency = EventNameChainBalances.Currency)
  WHERE EventNameChainBalances.TransferSystemID = 3
    AND EventNameChainBalances.TransferStateID = 12
    AND (Transfers.TriggeredSettle IS NOT NULL OR Transfers.TriggeredRefund IS NOT NULL)
    AND EventNameChainBalances.EntryStepID = :'entrystepID'
    AND Transfers.Datestamp >= now() - '7 days'::interval
    AND EventNameChainBalances.OrderDate >= now() - '7 days'::interval
    --AND Transfers.UserID = GET_USERID('unibet')
    --AND EventNameChainBalances.ToTransferBankAccountID = (SELECT TransferBankAccountID FROM BankAccounts WHERE EcoSysAccount = 'CLIENT_FUNDS_NETHERLANDS_CITI')
  GROUP BY 1, 2
  ORDER BY 1, 2;

\echo 'Values take last 7 days into account'
