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
     --Remove PNPOrders as PnpLogins do not follow unique TransferBankAccountID and here we are searching for end user acitivty pertaining to a particular transferbankaccountID. PNP deposits will be in bankorders.
   /*UNION
  SELECT DISTINCT PnpOrders.OrderID, Users.username, TransferBankAccountID
    FROM KYC.PnpOrders
    JOIN Orders ON Orders.OrderID = PnpOrders.OrderID
    JOIN Users ON Users.UserID = Orders.UserID
    JOIN KYC.bankentitiesaccounts ON kyc.bankentitiesaccounts.BankEntityID = KYC.PNPOrders.BankEntityID
   WHERE TransferBankAccountID = :'transferbankaccountID'
     AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)*/
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
             NULLIF(concat(Notifications.request::json->'data'->'attributes'->>'name', ', ', Notifications.request::json->'data'->'attributes'->>'personid'),', ') AS AccountNotificationData,
             Orders.EnduserID,
             kyc.Entities.PublicEntityID,
             COALESCE(TransferBankAccounts.PersonID, Public.ENtities.PersonID, Kyc.OrdersVerifiedKYCData.PersonID, KYC.Entities.PersonID, PnpOrders.PersonID, OrdersKYCData.PersonID) AS PersonID,
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

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'all_enduser_activity');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
