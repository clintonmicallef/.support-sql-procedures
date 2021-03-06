/* Get the reason for a delayed credit */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT Orders.OrderID, TransferStates.Name AS TransferState,
       (CASE WHEN DecisionLog.Reason = 'Amount is greater than DepositLimit' AND EXISTS (SELECT 1 FROM ExceededExposureLimits WHERE OrderID = Orders.OrderID) THEN 'Exceeded ExposureL limit'::text
             WHEN DecisionLog.Reason = 'Amount is greater than DepositLimit' THEN 'Previously Failed Deposit'::text
             ELSE DecisionLog.Reason END) AS Reason,
       OrdersKYCData.name, OrdersKYCData.dob, OrdersKYCData.personID, OrdersKYCData.gender, OrdersKYCData.address, OrdersKYCData.zipcode, OrdersKYCData.city, OrdersKYCData.country, OrdersKYCData.email,
       Orders.Datestamp
  FROM Orders
  LEFT JOIN OrdersKYCData ON (OrdersKYCData.OrderID = Orders.OrderID)
  JOIN BankOrders ON (BankOrders.OrderID = Orders.OrderID)
  JOIN BankOrderTransfers ON (BankOrderTransfers.OrderID = Orders.OrderID)
  JOIN Transfers ON (Transfers.TransferID = BankOrderTransfers.TransferID)
  JOIN TransferStates ON (TransferStates.TransferStateID = Transfers.TransferStateID)
  JOIN EntrySteps ON (EntrySteps.EntryStepID = Orders.EntryStepID)
  LEFT JOIN risk.DecisionLog ON (DecisionLog.OrderID = Orders.OrderID)
 WHERE Orders.OrderID = :'orderid'
;
