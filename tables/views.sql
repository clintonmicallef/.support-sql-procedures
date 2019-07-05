-- Create temporary table with list of all files in /views directory
\cd :local_path_supportsqlprocedures/views
DROP TABLE IF EXISTS pg_temp.SupportSQL_Views;
CREATE TEMP TABLE SupportSQL_Views(Filename text, Comment text);
\COPY pg_temp.SupportSQL_Views FROM PROGRAM 'for f in *.sql; do <"$f" read line; printf "$f;$line\n"; done' DELIMITER ';';
