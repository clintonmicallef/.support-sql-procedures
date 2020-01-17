/* Function used for gdpr_request.sql procedure */

CREATE OR REPLACE FUNCTION pg_temp.Get_related_orderids(_OrderID bigint)
     RETURNS TABLE(orderIDs bigint, TransferbankaccountIDs integer)
     LANGUAGE plpgsql
 AS $function$

 BEGIN

 RETURN QUERY
 WITH Get_TransferBankAccountID AS(
 SELECT COALESCE(BankOrders.TransferBankAccountID, OrderBankAccounts.TransferBankAccountID, (CASE WHEN BankOrderTransfers.FROMTransferBankAccountID IN (SELECT TransferBankAccountID FROM BankAccounts WHERE TransferBankAccountID = BankOrderTransfers.FROMTransferBankAccountID) THEN BankOrderTransfers.TOTransferBankAccountID ELSE BankOrderTransfers.FROMTransferBankAccountID END), AccountSelectorTransfers.TransferBankAccountID, AutogiroTransferBankAccount.TransferBankAccountID, kyc.bankentitiesaccounts.TransferBankAccountID) AS TransferBankAccountID
   FROM Orders
   LEFT JOIN BankOrders ON BankOrders.OrderID = Orders.OrderID
   LEFT JOIN OrderBankAccounts ON OrderBankAccounts.OrderID = Orders.OrderID
   LEFT JOIN BankorderTransfers ON BankorderTransfers.OrderID = Orders.OrderID
   LEFT JOIN AccountSelectorTransfers ON AccountSelectorTransfers.OrderID = Orders.OrderID
   LEFT JOIN autogiro.UserManDateOrders ON UserManDateOrders.OrderID = Orders.OrderID
   LEFT JOIN autogiro.payers ON payers.payerID = usermandateorders.payerID
   LEFT JOIN TransferBankAccounts AutogiroTransferBankAccount ON AutogiroTransferBankAccount.AccountID = autogiro.Payers.AccountID
   LEFT JOIN KYC.PNPOrders ON PNPOrders.OrderID = Orders.OrderID
   LEFT JOIN KYC.bankentitiesaccounts ON kyc.bankentitiesaccounts.BankEntityID = KYC.PNPOrders.BankEntityID
  WHERE Orders.OrderID = _orderID
 ),
 Get_PersonIDs AS(
 SELECT PersonIDs, TransferBankAccountID
   FROM TransferBankAccounts
  WHERE TransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_TransferBankAccountID)
 ),
 Get_Related_TransferBankAccounts AS(
 SELECT TransferBankAccounts.TransferBankAccountID
   FROM TransferBankAccounts
  WHERE (SELECT personIds FROM Get_PersonIDs) && TransferBankAccounts.personids
 )
 SELECT DISTINCT BankOrders.OrderID, TransferBankAccountID
   FROM BankOrders
  WHERE BankOrders.TransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts)
    AND BankOrders.Datestamp >= now() -'24 months'::interval
  UNION
 SELECT DISTINCT orderbankaccounts.OrderID, TransferBankAccountID
   FROM orderbankaccounts
   WHERE orderbankaccounts.TransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts)
     AND orderbankaccounts.Datestamp >= now() -'24 months'::interval
  UNION
  /*SELECT DISTINCT OrderID
    FROM bankordertransfers
   WHERE bankordertransfers.FromTransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts)
     AND bankordertransfers.Datestamp >= now() -'24 months'::interval
  UNION
  SELECT DISTINCT OrderID
     FROM BankorderTransfers
     WHERE  bankordertransfers.ToTransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts)
      AND bankordertransfers.Datestamp >= now() -'24 months'::interval
   UNION*/ -- DO WE NEED BankOrderTransfers ??
  SELECT DISTINCT accountselectortransfers.OrderID, TransferBankAccountID
    FROM accountselectortransfers
    WHERE accountselectortransfers.TransferBankAccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts)
      AND accountselectortransfers.Datestamp >= now() -'24 months'::interval
 UNION
 SELECT DISTINCT autogiro.usermandateorders.OrderID, TransferBankAccountID
   FROM autogiro.usermandateorders
   JOIN autogiro.payers ON payers.payerID = usermandateorders.payerID
   JOIN TransferBankAccounts ON TransferBankAccounts.AccountID = autogiro.Payers.AccountID
  WHERE payers.AccountID IN (SELECT AccountID FROM TransferBankAccounts WHERE TransferbankaccountID IN (SELECT TransferBankAccountID FROM Get_Related_TransferBankAccounts))
    AND usermandateorders.Datestamp >= now() -'24 months'::interval;

 RETURN;
 END;
 $function$
 ;
