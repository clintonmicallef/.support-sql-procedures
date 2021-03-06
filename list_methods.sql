/* Search and display all SupportSQL_ methods */
/* {description: "Search and display all SupportSQL_ methods", category: "Manual"} */
\set QUIET ON

\pset expanded off

\prompt 'Display all methods by pressing ENTER or search using a keyword: ', keyword

SELECT Type,
       substring(Filename, '(.*)\.sql$') AS Filename,
       CASE
          WHEN Type = 'Procedure' THEN format(':%s', substring(Filename, '(.*)\.sql$'))
          WHEN Type = 'Function' THEN format('pg_temp.%s(_parameters)', substring(Filename, '(.*)\.sql$'))
          WHEN Type = 'View' THEN format('%s', substring(Filename, '(.*)\.sql$'))
       END AS Invocation,
       Comment
  FROM (
    SELECT 'Procedure'::text AS Type, Filename, Comment FROM pg_temp.SupportSQL_Procedures
    UNION ALL
    SELECT 'Function'::text AS Type, Filename, Comment FROM pg_temp.SupportSQL_Functions
    UNION ALL
    SELECT 'View'::text AS Type, Filename, Comment FROM pg_temp.SupportSQL_Views
  ) AS SupportSQL_Schema
 WHERE TRUE
   AND (CASE WHEN NULLIF(:'keyword','') IS NOT NULL THEN format('%s %s', substring(FileName, '(.*)\.sql$'), Comment) ILIKE '%' || :'keyword' || '%' ELSE TRUE END)
 ORDER BY 1, 2;
