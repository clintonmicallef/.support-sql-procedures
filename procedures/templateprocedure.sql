/* PROCEDURE:Place Description here*/

\prompt 'message', variableName
\prompt 'message', variableName2

\set QUIET ON

\pset expanded off --Sets the view ON/OFF as \x does


SELECT 1
  FROM orders
 WHERE OrderID = :'variableName'
   AND userID = :'variableName2'
;



-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'templateprocedure');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'


--BELOW IS OLD
-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'all_enduser_activity.sql'); --Change to name of file!!!***
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
