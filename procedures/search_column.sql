/* Search DB Tables using a particular attributes/column */

\prompt 'Please enter an attribute', keyword

\pset expanded off

SELECT table_schema, table_name, column_name
  FROM information_schema.columns
 WHERE column_name ILIKE '%' || :'keyword' || '%';
