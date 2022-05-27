--Procedure to obtain backoffice sessionuuid for manual bulk cURLs 2nd line does to run backoffice functions
--see get_backoffice_sessionuuid_helper.sh in repository

\set QUIET ON

--Executes get_backoffice_sessionuuid_helper.sh
\! ~/.support-sql-procedures/scripts/get_backoffice_sessionuuid_helper.sh

--Creates a temp table to store curl result
DROP TABLE IF EXISTS pg_temp.backofficepasswordresult;
CREATE TEMP TABLE backofficepasswordresult(curlresult json);


--Import from get_backoffice_sessionuuid_helper.sh's output.txt
\COPY pg_temp.backofficepasswordresult FROM '~/output.txt';

--Take sessionuuid as follows:
SELECT curlresult::json->'result'->>'sessionuuid' AS Backoffice_sessionuuid FROM backofficepasswordresult;

--Delete curl result output from file
\! rm ~/output.txt
