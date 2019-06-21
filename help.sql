/*Queries SupportSQLRepository table with search functionality*/

\pset expanded off

\prompt 'Please enter a keyword or press enter to see full list', keyword


SELECT aliasname, comment
  FROM supportsqlaliases
 WHERE TRUE
   -- AND :'keyword' ILIKE '%' || REPLACE(REPLACE((supportsqlaliases.category)::text, '{','')::text,'}','') || '%'
   -- Below my suggestions. First one which is commented look for exact word, therefore using ILIKE is probably better : )
   -- AND ARRAY[:'keyword']::text[] && category
   AND (CASE WHEN NULLIF(:'keyword','') IS NOT NULL THEN (array_to_string(category, ',') ILIKE '%' || :'keyword' || '%') ELSE TRUE END)
   ;
