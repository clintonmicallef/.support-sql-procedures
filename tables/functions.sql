-- Create temporary table with list of all files in /functions directory
\cd :local_path_supportsqlprocedures/functions
DROP TABLE IF EXISTS pg_temp.SupportSQL_Functions;
CREATE TEMP TABLE SupportSQL_Functions(Filename text, Comment text);
\COPY SupportSQL_Functions FROM PROGRAM 'for f in *.sql; do <"$f" read line; printf "$f;$line\n"; done' DELIMITER ';';
