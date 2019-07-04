/*Queries SupportSQLRepository table with search functionality*/

\pset expanded off

\prompt 'Please enter a keyword or press enter to see full list', keyword

SELECT substring(FileName, '(.*)\.sql$') AS Alias,
       Comment
  FROM SupportSQL_Procedures
 WHERE TRUE
   AND (CASE WHEN NULLIF(:'keyword','') IS NOT NULL THEN format('%s %s', substring(FileName, '(.*)\.sql$'), Comment) ILIKE '%' || :'keyword' || '%' ELSE TRUE END);
