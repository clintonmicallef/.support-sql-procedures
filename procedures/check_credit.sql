/* Checks whether credit was pushed by merchant or ourselves */
/* {description: "Checks  whether credit was pushed by merchant or ourselves ", category: "Risk"} */

\prompt 'Please enter an OrderID', orderID

\set QUIET ON

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

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'check_credit.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
