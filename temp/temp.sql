-- TEMP Examples of copy
-- https://www.postgis.us/presentations/PGOpen2018_data_loading.pdf

-- \COPY supportsqlprocedures_procedures FROM PROGRAM 'find /Users/lukaszhanusik/.support-sql-procedures/procedures -maxdepth 1 -type f -printf "%f\n"';
-- \COPY supportsqlprocedures_procedures_details FROM PROGRAM 'for f in *.sql; do <"$f" read line; printf "$f,$line\n"; done' WITH (format 'csv');
-- \COPY supportsqlprocedures_procedures_details FROM PROGRAM 'for f in *.sql; do <"$f" read line; printf "$f;$line\n"; done' DELIMITER ';';

-- head -1 procedures/* | awk 'NR > 1 { print $9 ":" $1 }'
-- awk "NR==1{print}" procedures/*
-- ls -l procedures/* | awk 'NR > 1 { print $9 ":" $1 }'
-- for f in procedures/*.sql; do <"$f" read line; printf "$f,$line\n"; done
