/* Details on how a Deposit was Failed */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT (CASE WHEN TRUE THEN 'Failed by User' ELSE NULL END) AS Case,
       UserAccessLog.Datestamp AS Datestamp,
       Users.Username AS Data
  FROM UserAccessLog
  JOIN Users ON (Users.UserID = UserAccessLog.UserID)
  LEFT JOIN Users Superusers ON (Superusers.UserID = UserAccessLog.SuperUserID)
  JOIN Functions ON Functions.FunctionID = UserAccessLog.FunctionID
  LEFT JOIN Transfers ON (Transfers.Datestamp = UserAccessLog.Datestamp) --  AND Transfers.TransferTypeID = 1)
  LEFT JOIN BankOrderTransfers ON (BankOrderTransfers.OrderID = Transfers.OrderID)
  LEFT JOIN Orders ON (Orders.OrderID = BankOrderTransfers.OrderID)
 WHERE Functions.FunctionID = Get_FunctionID('Fail_Deposit_Transfer')
   AND Orders.Orderid = :'orderid'
   AND Transfers.TransferID IS NOT NULL
 UNION
SELECT (CASE WHEN TRUE THEN 'Failed by AutoFail' ELSE NULL END) AS Case,
       depositautofaillog.Failed AS Datestamp,
       depositautofaillog.message AS Data
  FROM depositautofaillog
 WHERE transferid IN (Select TransferID from Transfers WHERE TransferTYpeID = 1 AND OrderID = :'orderid')
   AND Failed IS NOT NULL
;

\echo 'If no results are given yet the Deposit is failed and credited, then it was most probably failed by a Trustly agent using the DB function.'
