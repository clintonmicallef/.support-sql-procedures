/* Search DB Tables using a similar table name */

\prompt 'Please enter a keyword', keyword

\set QUIET ON

\pset expanded off

SELECT table_schema, table_name
  FROM information_schema.tables
 WHERE table_name ILIKE '%' || :'keyword' || '%';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'search_table');
\i '~/.support-sql-procedures/userlogsetup.psql'
