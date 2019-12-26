/* PROCEDURE:Shows all activty of the end user's particular bank account (TransferBankAccountID) with Trustly */

\prompt 'Please enter a TransferBankAccountID (one or more)', transferbankaccountID
\prompt 'Please enter a ProcessingAccount or press enter to continue', processingaccount

\set QUIET ON

\pset expanded off

WITH EnduserOrders AS(
  SELECT DISTINCT BankOrders.OrderID, Users.Username, TransferBankAccountID
    FROM BankOrders
    JOIN Orders ON Orders.OrderID = BankOrders.OrderID
    JOIN Users ON Users.UserID = Orders.UserID
   WHERE TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
   UNION
  SELECT DISTINCT OrderBankAccounts.OrderID, Users.Username, TransferBankAccountID
    FROM orderbankaccounts
    JOIN Orders ON Orders.OrderID = OrderBankAccounts.OrderID
    JOIN Users ON Users.UserID = Orders.UserID
   WHERE TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
   UNION
  SELECT DISTINCT OrderID, Users.Username, TransferBankAccountID
    FROM accountselectortransfers
    JOIN Users ON Users.UserID = accountselectortransfers.UserID
   WHERE TransferBankAccountID = :'transferbankaccountID'
    AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
   UNION
  SELECT DISTINCT Transfers.OrderID, Users.Username, TransferBankAccounts.TransferBankAccountID
    FROM autogiro.payments
    JOIN Users ON Users.UserID = autogiro.payments.UserID
    JOIN Transfers ON Transfers.TransferID = payments.TransferID
    JOIN autogiro.payers ON payments.payerid = payers.payerid
    JOIN TransferBankAccounts ON TransferBankAccounts.AccountID = autogiro.Payers.AccountID
    WHERE TransferBankAccounts.TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
   UNION
  SELECT DISTINCT PnpOrders.OrderID, Users.username, TransferBankAccountID
    FROM KYC.PnpOrders
    JOIN Orders ON Orders.OrderID = PnpOrders.OrderID
    JOIN Users ON Users.UserID = Orders.UserID
    JOIN KYC.bankentitiesaccounts ON kyc.bankentitiesaccounts.BankEntityID = KYC.PNPOrders.BankEntityID
   WHERE TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
  )
      SELECT EnduserOrders.OrderID,
             EnduserOrders.Username AS ProcessingAccount,
             COALESCE(OrdersKYCData.Name, TransferBankAccounts.Name) AS Enduser_name,
             Orders.EnduserID,
             TransferBankAccounts.PersonID,
             WorkerTypes.name AS OrderType,
             Orders.datestamp::timestamp(0) AS Initiated_On,
             Orders.APIAmount,
             TransferBankaccounts.Balance,
             Orders.APICurrency
        FROM EnduserOrders
        JOIN Orders ON EnduserOrders.OrderID = Orders.OrderID
        JOIN TransferBankAccounts ON TransferBankAccounts.TransferBankAccountID = EnduserOrders.transferbankaccountID
        LEFT JOIN OrdersKYCData ON OrdersKYCData.OrderID = EnduserOrders.OrderID
        LEFT JOIN Workertypes ON Workertypes.WorkertypeID = Orders.InitOrderTypeID
       ORDER BY Orders.datestamp ASC
;

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'all_enduser_activity.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
