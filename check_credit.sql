/*Cheks whether credit was pushed by merchant or ourselves*/

\prompt 'Please enter an OrderID', orderID

\pset expanded on

SELECT (CASE WHEN TRUE THEN 'Merchant_Credit' ELSE NULL END) AS Case,
       datestamp AS Datestamp,
       superuser AS SuperUser
  FROM vUserAccessLog
 WHERE function = 'Send_Credit'
   AND datestamp::timestamp(0) IN (SELECT datestamp::timestamp(0) FROM notifications WHERE OrderID = :'orderID')
 UNION
SELECT (CASE WHEN TRUE THEN 'Trustly_Credit' ELSE NULL END) AS Case,
       datestamp AS Datestamp,
       fixedby AS SuperUser
  FROM FixedOrders
 WHERE OrderID = :'orderID'
;

\echo "If no results, credit not sent or credit sent automatically through system"
