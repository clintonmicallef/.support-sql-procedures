/* Search DB Tables using a particular attributes/column */

\prompt 'Please enter an attribute', keyword

\set QUIET ON

\pset expanded off

SELECT table_schema, table_name, column_name
  FROM information_schema.columns
 WHERE column_name ILIKE '%' || :'keyword' || '%';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'search_column');
\i '~/.support-sql-procedures/userlogsetup.psql'
