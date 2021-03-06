/* PROCEDURE:Shows all activty of the end user's particular bank account (TransferBankAccountID) with Trustly */

\prompt 'Please enter a TransferBankAccountID', transferbankaccountID
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
  SELECT DISTINCT ordersentity.OrderID, Users.Username, bankentitiesaccounts.TransferBanKAccountID
    FROM Kyc.bankentitiesaccounts
    JOIN kyc.ordersentity ON ordersentity.bankentityID = kyc.bankentitiesaccounts.bankentityID
    JOIN orders ON orders.orderid=kyc.OrdersEntity.orderID
    JOIN Users ON Users.UserID = Orders.UserID
   WHERE Kyc.bankentitiesaccounts.TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
  )
      SELECT Orders.datestamp::timestamp(0) AS Datestamp,
             EnduserOrders.OrderID,
             EnduserOrders.Username AS ProcessingAccount,
             OrdersVerifiedKYCData.Name AS VerifiedKYC,
             Kyc.Entities.Name AS KYCEntity,
             Public.Entities.Name AS Entities,
             concat(PNPOrders.kycdata::json->>'firstname',' ', PNPOrders.kycdata::json->>'lastname') AS PNPOrders,
             TransferbanKAccounts.Name AS TransferBankAccount,
             OrdersKYCData.Name AS LegacyOrderKYCData,
             unaccent(lower(concat(OrderAttributes.firstname, ' ',OrderAttributes.lastname)))::text AS OrderAttributes,
             COALESCE(Notifications.request::json->'data'->'attributes'->>'name', Notifications.dataparam::json->'attributes'->>'name') AS AccountNotification,
             Orders.EnduserID,
             kyc.Entities.PublicEntityID,
             COALESCE(TransferBankAccounts.PersonID, Public.ENtities.PersonID, Kyc.OrdersVerifiedKYCData.PersonID, KYC.Entities.PersonID, PnpOrders.PersonID, OrdersKYCData.PersonID) AS PersonID,
             KYC.Entities.KycEntityID,
             concat(WorkerTypes.name,' ',OrderStepsinWAPIRAPI.Name) AS OrderType,
             Orders.PaymentAmount,
             Orders.PaymentCurrency
        FROM EnduserOrders
        JOIN Orders ON EnduserOrders.OrderID = Orders.OrderID
        LEFT JOIN Notifications ON Notifications.ApiMethod = 'account' AND Notifications.OrderID = Orders.OrderID
        LEFT JOIN Public.Entities ON Entities.EntityID = Orders.EntityID
        LEFT JOIN OrderAttributes ON (OrderAttributes.OrderID = EnduserOrders.orderid) AND (Orderattributes.FirstName IS NOT NULL) AND (OrderAttributes.LastName IS NOT NULL)
        LEFT JOIN OrdersKycData ON (OrdersKycData.OrderID = EnduserOrders.orderid)
        LEFT JOIN KYC.OrdersVerifiedKYCData ON OrdersVerifiedKYCData.OrderID = EnduserOrders.OrderID
        LEFT JOIN KYC.PnpOrders ON (KYC.PnpOrders.OrderID = EnduserOrders.orderid)
        LEFT JOIN KYC.OrdersEntity ON KYC.OrdersEntity.OrderID = EnduserOrders.orderid
        LEFT JOIN KYC.Entities ON (KYC.Entities.kycentityid = KYC.ordersentity.kycentityid)
        LEFT JOIN kyc.endusers ON  kyc.endusers.kycenduserID = KYC.OrdersEntity.kycenduserID
        LEFT JOIN TransferBankAccounts ON TransferBankAccounts.TransferBankAccountID = EnduserOrders.transferbankaccountID
        LEFT JOIN Workertypes ON Workertypes.WorkertypeID = Orders.InitOrderTypeID
        LEFT JOIN LATERAL(
          SELECT DISTINCT OrderTypeID, OrderStepWorkerTypes.Name
            FROM OrderSteps
            JOIN WorkerTypes OrderStepWorkerTypes ON OrderStepWorkerTypes.WorkerTypeID = OrderSteps.OrderTypeID
           WHERE OrderSteps.OrderID = Orders.OrderID
             AND OrderStepWorkerTypes.Name IN ('WAPI','RAPI')
           ) AS OrderStepsinWAPIRAPI ON TRUE
       ORDER BY Orders.datestamp ASC
;

\echo **********************************************************************************************************
\echo Definitions:
\echo 1. verifiedkyc -> name we send in account notification to merchant
\echo 2. kycentity -> name we captured from end user bank login
\echo 3. entities -> Legacy name storage
\echo 4. pnporders -> name we capture during a PNP deposit from online bank
\echo 5. transferbankaccount -> dynamically changing name according to what we find in online bank account
\echo 6. legacyorderkycdata -> name storage up till august 2020
\echo 7. orderattributes -> name merchant is sending us in their api call (unverified)
\echo 8. accountnotification -> name we send in account notification to merchant (before we had verifiedkyc model)
\echo **********************************************************************************************************
