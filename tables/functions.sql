-- Create temporary table with list of all files in /functions directory
\cd :local_path_supportsqlprocedures/functions
\set QUIET ON
DROP TABLE IF EXISTS pg_temp.SupportSQL_Functions;
CREATE TEMP TABLE SupportSQL_Functions(Filename text, Comment text);
\COPY pg_temp.SupportSQL_Functions FROM PROGRAM 'search="\\/{0,1}\*\\/{0,1}" && replace=; for file in *.sql; do < ${file} read line; lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`; printf "${file};${lineRegexed}\n"; done' DELIMITER ';';


-- Bash program expanded to smaller lines
-- search='/{0,1}\*/{0,1}' && replace=''
-- for file in *.sql
--   do
--     < ${file} read line
--     lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`
--     printf "${file};${lineRegexed}\n"
--   done
-- search='/{0,1}\*/{0,1}' && replace=''; for file in *.sql; do < ${file} read line; lineRegexed=`sed -E "s|${search}|${replace}|g; s/--//g; s/^[ ]+//g" <<< ${line}`; printf "${file};${lineRegexed}\n"; done
