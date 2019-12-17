/* Search DB Tables using a similar table name */

\prompt 'Please enter a keyword', keyword

\set QUIET ON

\pset expanded off

SELECT table_schema, table_name
  FROM information_schema.tables
 WHERE table_name ILIKE '%' || :'keyword' || '%';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'search_table.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
