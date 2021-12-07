/* Find a common column for JOINs.*/

\echo ''

\prompt 'Please enter a table1', table1
\prompt 'Please enter a table2 you want to join', table2


\set QUIET ON

\pset footer off
\pset expanded OFF
\timing OFF

\echo ''
\echo '*****************'
\echo '*   RELATIONS   *'
\echo '*****************'
\echo ''

SELECT
    DISTINCT a.table_name || '.' || a.column_name AS "table1.column",
    b.table_name || '.' || b.column_name AS "table2.column",
    CASE
        WHEN a.ordinal_position = 1 OR b.ordinal_position = 1 THEN 'TRUE'
        ELSE NULL
    END AS "primary_key"
FROM
    information_schema.columns a
    JOIN information_schema.columns b ON a.column_name = b.column_name
WHERE
    a.table_name = :'table1'
    AND b.table_name = :'table2'
    AND (
        a.column_name != 'datestamp'
        OR b.column_name != 'datestamp'
    );

\echo 'Always try to use Primary/Foreign keys to join your tables if possible!'

\echo ''
\echo '*****************'
\echo '*  JOIN FORMAT  *'
\echo '*****************'
\echo ''
\echo 'FROM'
\echo '   table1'
\echo '   JOIN table2 ON table1.column = table2.column'
\echo ''
