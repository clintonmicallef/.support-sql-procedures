/* 2nd Line procedure to query risky deposits and fail according to input by 2nd line agent. Note that validation for access privelages done in risky_deposots() function*/

\set QUIET ON

\pset expanded off

--Performs a 1st check on agent running this
SELECT (CASE WHEN user NOT IN ('tomasvebr', 'benjaminschembri', 'dimitriossliakas') THEN 'Unauthorised Access - please exit' ELSE 'Please wait...' END) AS Notice;


SELECT * FROM pg_temp.secondline_view_risky_deposits(); --Performs a 2nd check and doesnt allow if non 2nd line


\prompt 'Would you like to fail the risky deposits? [yes / no]', answer
\echo ''


SELECT * from pg_temp.secondline_fail_risky_deposits(trim(:'answer'));  --Performs a 3rd check and does not allow any actions to run if not 2nd line agent




-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'risky_deposits');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
