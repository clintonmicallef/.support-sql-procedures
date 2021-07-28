/* Details on how a Deposit got Refunded */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

WITH Parameters AS(
  SELECT Orders.Orderid,
         Orders.Datestamp,
         Transfers.Datestamp AS DebitDatestamp,
         Users.Username
    FROM Orders
    LEFT JOIN Transfers ON Transfers.OrderID = Orders.ORderID AND Transfers.TransferTypeID = 4
    JOIN Users ON Users.UserID = Orders.UserID
   WHERE Orders.OrderID = :'orderid'
   ORDER BY DebitDatestamp DESC
   LIMIT 1
 )
 SELECT (CASE WHEN APICalls.APICallID IS NOT NULL THEN 'Merchant Refund via API' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        'apicallID ' || APICalls.APICallID::text  AS Data
   FROM APICalls
  WHERE Method = 'Refund' AND
        Username IN (SELECT Username FROM Parameters) AND
        Datestamp BETWEEN (SELECT Datestamp FROM Parameters) AND ((SELECT DebitDatestamp FROM Parameters) + interval '10 mins') AND
        (((SignedResult::json->'data'->>'orderid')::bigint = (SELECT OrderID FROM Parameters)::bigint) OR ((resultdata::json->>'orderid')::bigint = (SELECT OrderID FROM Parameters)::bigint))
  UNION
 SELECT (CASE WHEN TRUE THEN 'Merchant Refund via Backoffice' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        'superuser ' || superuser::text AS Data
   FROM vUserAccessLog
  WHERE function = 'Manual_Refund'
    AND datestamp::timestamp(0) IN (SELECT DebitDatestamp::timestamp(0) FROM Parameters)
  UNION
 SELECT (CASE WHEN TRUE THEN 'Merchant Refund via Backoffice' ELSE NULL END) AS Case,
        queuedrefunds.datestamp AS Datestamp,
        'superuser ' || superuser::text AS Data
   FROM queuedrefunds
   JOIN vuserAccessLog ON  vuserAccessLog.datestamp = queuedrefunds.datestamp
  WHERE vuserAccessLog.function = 'Manual_Refund'
    AND queuedrefunds.orderid = (SELECT OrderID FROM Parameters)
  UNION
 SELECT (CASE WHEN TRUE THEN 'Refund Settled Interrupted Order - System cancel' ELSE NULL END),
        DepositRefundQueue.DAtestamp,
        'refund_date ' ||DepositRefundQueue.Refunded::timestamp(0)::text AS DAta
   FROM Transfers
   JOIN DepositRefundQueue ON DepositRefundQueue.TransferID = Transfers.TransferID
  WHERE Transfers.TransferTypeID = 1
    AND Transfers.TriggeredDebit IS NULL --DO not confuse with failed orders
    AND Transfers.orderID = (SELECT OrderID FROM Parameters)
  UNION
 SELECT (CASE WHEN TRUE THEN 'Refund due to Failed deposit now Settled and OK to Debit notification'
              ELSE 'Not Found! Report to Administrator' END) AS Case,
        Transfers.TriggeredRefund AS Datestamp,
        'Failed_date ' || Transfers.triggereddebit::timestamp(0)::text AS Data
   FROM Transfers
   JOIN transferstatetransitions ON transferstatetransitions.TransferID = Transfers.TransferID AND transferstatetransitions.ToTransferStateID = 8
  WHERE Transfers.TransferTypeID = 1
    AND Transfers.TriggeredDebit IS NOT NULL
    AND Transfers.TransferSTateID = 12
    AND Transfers.OrderID IN (SELECT OrderID FROM Parameters)
    AND EXISTS(SELECT 1 from transfers refundwithdrawal where refundwithdrawal.transfertypeid = 2 and refundwithdrawal.orderid=transfers.orderid)
;
