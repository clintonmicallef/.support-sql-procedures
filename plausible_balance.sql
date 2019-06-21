/*All deposit of enduser based on PersonID along with Balance of end user's bank account to determine Plausible Balance*/

\prompt 'Please enter the PersonID', personID

\pset expanded off

SELECT BankOrders.OrderID,
       BankOrders.Datestamp::timestamp(0),
       BankOrders.TotalAmount,
       BankOrders.Balance,
       BankOrderTransfers.TransferID,
       Transfers.TriggeredSettle::timestamp(0),
       Transfers.TriggeredCredit::timestamp(0),
       TransferStates.Name AS PreviousTransferState,
       CurrentTransferState.Name AS CurrentTransferState
  FROM BankOrders
  JOIN BankOrderTransfers ON (BankOrderTransfers.OrderID = BankOrders.OrderID)
  JOIN Transfers ON (Transfers.TransferID = BankOrderTransfers.TransferID)
  LEFT JOIN TransferStateTransitions ON (TransferStateTransitions.TransferID = BankOrderTransfers.TransferID AND TransferStateTransitions.ToTransferStateID = 12 /*SETTLED*/)
  LEFT JOIN TransferStates ON (TransferStates.TransferStateID = TransferStateTransitions.FromTransferStateID)
  LEFT JOIN TransferStates CurrentTransferState ON (CurrentTransferState.TransferStateID = Transfers.TransferStateID)
 WHERE BankOrders.PersonID = :'personID'
   AND BankOrders.Datestamp > current_date-20;
