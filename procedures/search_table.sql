/* Search DB Tables using a similar table name */

\prompt 'Please enter a keyword', keyword

\pset expanded off

SELECT table_schema, table_name
  FROM information_schema.tables
 WHERE table_name ILIKE '%' || :'keyword' || '%';
