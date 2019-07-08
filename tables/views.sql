-- Create temporary table with list of all files in /views directory
\cd :local_path_supportsqlprocedures/views
\set QUIET ON
DROP TABLE IF EXISTS pg_temp.SupportSQL_Views;
CREATE TEMP TABLE SupportSQL_Views(Filename text, Comment text);
\COPY pg_temp.SupportSQL_Views FROM PROGRAM 'search="\\/{0,1}\*\\/{0,1}" && replace=; for file in *.sql; do < ${file} read line; lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`; printf "${file};${lineRegexed}\n"; done' DELIMITER ';';


-- Bash program expanded to smaller lines
-- search='/{0,1}\*/{0,1}' && replace=''
-- for file in *.sql
--   do
--     < ${file} read line
--     lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`
--     printf "${file};${lineRegexed}\n"
--   done
-- search='/{0,1}\*/{0,1}' && replace=''; for file in *.sql; do < ${file} read line; lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`; printf "${file};${lineRegexed}\n"; done
