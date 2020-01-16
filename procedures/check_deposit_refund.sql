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
 )
 SELECT (CASE WHEN APICalls.APICallID IS NOT NULL THEN 'Merchant Refund via API' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        APICalls.APICallID::text AS Data
   FROM APICalls
  WHERE Method = 'Refund' AND
        Username IN (SELECT Username FROM Parameters) AND
        Datestamp BETWEEN ((SELECT DebitDatestamp FROM Parameters) - interval '10 mins') AND ((SELECT DebitDatestamp FROM Parameters) + interval '10 mins') AND
        (SignedResult::json->'data'->>'orderid')::bigint = (SELECT OrderID FROM Parameters)::bigint
  UNION
 SELECT (CASE WHEN TRUE THEN 'Merchant Refund via Backoffice' ELSE NULL END) AS Case,
        datestamp AS Datestamp,
        superuser::text AS Data
   FROM vUserAccessLog
  WHERE function = 'Manual_Refund'
    AND datestamp::timestamp(0) IN (SELECT DebitDatestamp::timestamp(0) FROM Parameters)
  UNION
 SELECT (CASE WHEN transferstatetransitions.TransferID IS NOT NULL
              THEN 'Refund due to Settlement after Transfer has been failed'
              ELSE 'System Cancel - Refund upon Settlement' END) AS Case,
        Transfers.TriggeredRefund AS Datestamp,
        COALESCE(transferstatetransitions.TransferID, Transfers.TransferID)::text AS Data
   FROM Transfers
   LEFT JOIN transferstatetransitions ON transferstatetransitions.TransferID = Transfers.TransferID AND transferstatetransitions.ToTransferStateID = 6
  WHERE Transfers.TransferTypeID = 1
    AND Transfers.TriggeredRefund IS NOT NULL
    AND Transfers.OrderID IN (SELECT OrderID FROM Parameters)
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'check_deposit_refund.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
