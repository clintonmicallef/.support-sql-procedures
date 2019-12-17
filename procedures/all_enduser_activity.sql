/* PROCEDURE:Shows all activty of the end user's particular bank account (TransferBankAccountID) with Trustly */

\prompt 'Please enter a TransferBankAccountID (one or more)', transferbankaccountID
\prompt 'Please enter a ProcessingAccount or press enter to continue', processingaccount

\set QUIET ON

\pset expanded off

WITH EnduserOrders AS(
 SELECT BankOrders.OrderID, Users.Username, BankOrders.Balance, BankOrders.PersonID
   FROM BankOrders
   JOIN Orders ON Orders.OrderID = BankOrders.OrderID
   JOIN Users ON Users.UserID = Orders.UserID
  WHERE TransferBankAccountID IN (:transferbankaccountID)
    AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
  UNION
 SELECT OrderBankAccounts.OrderID, Users.Username, NULL::bigint, 'NULL'::text
   FROM OrderBankAccounts
   JOIN Orders ON Orders.OrderID = OrderBankAccounts.OrderID
   JOIN Users ON Users.UserID = Orders.UserID
  WHERE TransferBankAccountID IN (:transferbankaccountID)
    AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
  ),
  MerchantCreditedOrders AS(
    SELECT superuser AS SuperUser,
           datestamp AS Datestamp
      FROM vUserAccessLog
     WHERE function = 'Send_Credit'
       AND datestamp IN (SELECT triggeredcredit FROM Transfers WHERE TransferTypeID = 1 AND Transfers.OrderID IN (SELECT DISTINCT OrderID FROM EnduserOrders))
     ),
     TrustlyCreditedOrders AS(
       SELECT OrderID,
              FixedBy
         FROM FixedOrders
        WHERE OrderID IN  (SELECT DISTINCT OrderID FROM EnduserOrders)
      )
      SELECT Users.Username AS ProcessingAccount,
             OrdersKYCData.Name AS Enduser_name,
             EnduserOrders.PersonID,
             Transfers.OrderID AS OrderID,
             Orders.EntrystepID,
             TransferTypes.name AS TransferType,
             Transfers.datestamp::timestamp(0) AS Initiated_On,
             TransferStates.Name AS TransferState,
             Transfers.ModificationDate::timestamp(0),
             Transfers.Amount,
             EnduserOrders.Balance,
             Transfers.Currency,
             (CASE WHEN Transfers.TriggeredCredit IS NOT NULL THEN COALESCE(MerchantCreditedOrders.SuperUser, TrustlyCreditedOrders.fixedby, 'System'::text) ELSE NULL END) AS Credited_By,
             Transfers.TriggeredCredit::timestamp(0) AS triggered_credit,
             Transfers.TriggeredDebit::timestamp(0) AS Triggered_debit,
             Transfers.TriggeredRefund::timestamp(0) AS Triggered_refund,
             Transfers.TriggeredSettle::timestamp(0) AS Triggered_settled,
             ROUND(ExceededExposureLimits.consumedlimit,2) AS Consumedimit,
             ROUND(ExceededExposureLimits.maxlimit,2) AS MaxLimit,
             decisionlog.Reason AS Risk_Log,
             array_agg(Orders.EnduserID) AS EnduserID
        FROM Orders
        JOIN EnduserOrders ON EnduserOrders.OrderID = Orders.OrderID
        LEFT JOIN OrdersKYCData ON OrdersKYCData.OrderID = Orders.OrderID
        JOIN Transfers ON Transfers.OrderID = Orders.OrderID AND Transfers.TransferTypeID IN (1,2)
        JOIN TransferStates ON TransferStates.TransferStateID = Transfers.TransferStateID
        JOIN TransferTypes ON TransferTypes.TransferTypeID = transfers.TransferTypeID
        JOIN Users ON Users.UserID = Transfers.UserID
        LEFT JOIN MerchantCreditedOrders ON MerchantCreditedOrders.datestamp = transfers.triggeredcredit
        LEFT JOIN TrustlyCreditedOrders ON TrustlyCreditedOrders.OrderID = Orders.OrderID
        LEFT JOIN risk.decisionlog ON risk.decisionlog.OrderID = Orders.OrderID
        LEFT JOIN ExceededExposureLimits ON ExceededExposureLimits.OrderID = Orders.OrderID
       WHERE Orders.OrderID IN (SELECT OrderID FROM EnduserOrders)
       GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
       ORDER BY 7 DESC
;

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'all_enduser_activity.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
