-- Create temporary table with list of all files in /procedures directory
\cd :local_path_supportsqlprocedures/procedures
DROP TABLE IF EXISTS SupportSQL_Procedures;
CREATE TEMP TABLE SupportSQL_Procedures(Filename text, Comment text);
\COPY SupportSQL_Procedures FROM PROGRAM 'for f in *.sql; do <"$f" read line; printf "$f;$line\n"; done' DELIMITER ';';
