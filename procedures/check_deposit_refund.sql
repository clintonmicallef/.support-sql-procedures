/* Details on how a Deposit got Refunded */

\prompt 'Please enter an OrderID', orderid

\pset expanded on

WITH Parameters AS(
  SELECT Orders.Orderid,
         Orders.Datestamp,
         Transfers.Datestamp AS DebitDatestamp,
         Users.Username
    FROM Orders
    LEFT JOIN Transfers ON Transfers.OrderID = Orders.ORderID AND Transfers.TransferTypeID = 4 AND Transfers.Amount = Orders.PaymentAmount
    JOIN Users ON Users.UserID = Orders.UserID
   WHERE Orders.OrderID = :'orderid'
 )
 SELECT (CASE WHEN TRUE THEN 'Merchant Refund via API' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        APICalls.APICallID::text AS Data
   FROM APICalls
  WHERE Method = 'Refund' AND
        Username = (SELECT Username FROM Parameters) AND
        Datestamp >= (SELECT Datestamp::date FROM Parameters) AND
        (SignedResult::json->'data'->>'orderid')::bigint = (SELECT OrderID FROM Parameters)
  UNION
 SELECT (CASE WHEN TRUE THEN 'Merchant Refund via Backoffice' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        superuser::text AS Data
   FROM vUserAccessLog
  WHERE function = 'Manual_Refund'
    AND datestamp::timestamp(0) IN (SELECT DebitDatestamp::timestamp(0) FROM Parameters)
  UNION
 SELECT (CASE WHEN TRUE THEN 'System Cancel - Refund upon Settlement' ELSE NULL END) AS Case,
        Transfers.TriggeredRefund AS Datestamp,
        'NULL'::text AS Data
   FROM Transfers
  WHERE Transfers.TransferTypeID = 1
    AND Transfers.TriggeredRefund IS NOT NULL
    AND Transfers.OrderID IN (SELECT OrderID FROM Parameters)
;
