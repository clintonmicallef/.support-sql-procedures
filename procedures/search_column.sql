/* Search DB Tables using a particular attributes/column */

\prompt 'Please enter an attribute', keyword

\set QUIET ON

\pset expanded off

SELECT table_schema, table_name, column_name
  FROM information_schema.columns
 WHERE column_name ILIKE '%' || :'keyword' || '%';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'search_column.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
