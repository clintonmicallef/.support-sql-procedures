/* REAL Function used for gdpr_request.sql procedure */


--Function to return all related transfebankaccountIDs from the single OrderID input
CREATE OR REPLACE FUNCTION pg_temp.Get_relalted_GDPR_TransferBankAccounts(_OrderID bigint)
   RETURNS integer[]
AS $function$

SELECT array_agg(TransferBankAccounts.TransferBankAccountID) AS TransferBankAccountIDs
  FROM TransferBankAccounts
 WHERE PersonIDs = ANY(
   SELECT PersonIDs
     FROM TransferBankAccounts
    WHERE TransferBankAccountID IN (
      SELECT DISTINCT
             COALESCE(BankOrders.TransferBankAccountID, OrderBankAccounts.TransferBankAccountID, (CASE WHEN BankOrderTransfers.FROMTransferBankAccountID IN (SELECT TransferBankAccountID FROM BankAccounts WHERE TransferBankAccountID = BankOrderTransfers.FROMTransferBankAccountID) THEN BankOrderTransfers.TOTransferBankAccountID ELSE BankOrderTransfers.FROMTransferBankAccountID END), AccountSelectorTransfers.TransferBankAccountID, AutogiroTransferBankAccount.TransferBankAccountID) AS TransferBankAccountID
        FROM Orders
        LEFT JOIN BankOrders ON BankOrders.OrderID = Orders.OrderID
        LEFT JOIN OrderBankAccounts ON OrderBankAccounts.OrderID = Orders.OrderID
        LEFT JOIN BankorderTransfers ON BankorderTransfers.OrderID = Orders.OrderID
        LEFT JOIN AccountSelectorTransfers ON AccountSelectorTransfers.OrderID = Orders.OrderID
        LEFT JOIN Transfers ON Transfers.OrderID = Orders.OrderID AND Transfers.TransferSystemID = 12 --Autogiro
        LEFT JOIN autogiro.payments ON payments.TransferID = Transfers.TransferID
        LEFT JOIN autogiro.payers ON payers.payerID = payments.payerID
        LEFT JOIN TransferBankAccounts AutogiroTransferBankAccount ON AutogiroTransferBankAccount.AccountID = autogiro.Payers.AccountID
       WHERE Orders.OrderID = _OrderID
     )
   )
;
$function$
LANGUAGE SQL;
