/* Search and display SupportSQL_ tables */
/* {description: "Search and display SupportSQL_ tables", category: "Manual"} */
\set QUIET ON

\pset expanded off

\prompt 'Please enter a search keyword or press enter to see full list of definitions', keyword

SELECT Type,
       (':' || substring(FileName, '(.*)\.sql$')) AS Alias,
       Comment
  FROM (
    SELECT 'Procedure'::text AS Type, FileName, Comment FROM pg_temp.SupportSQL_Procedures
    --Removing Functions & Views from Help due to redundant functionality at this point
    /*UNION ALL
    SELECT 'Function' AS Type, FileName, Comment FROM pg_temp.SupportSQL_Functions
    UNION ALL
    SELECT 'View' AS Type, FileName, Comment FROM pg_temp.SupportSQL_Views*/
  ) AS SupportSQL_Schema
 WHERE TRUE
   AND (CASE WHEN NULLIF(:'keyword','') IS NOT NULL THEN format('%s %s', substring(FileName, '(.*)\.sql$'), Comment) ILIKE '%' || :'keyword' || '%' ELSE TRUE END)
 ORDER BY 1, 2;
