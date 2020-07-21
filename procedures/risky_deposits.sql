/* 2nd Line procedure to query risky deposits and fail according to input by 2nd line agent. Note that validation for access privelages done in risky_deposots() function*/

\set QUIET ON

\pset pager off

\pset expanded off

\echo 'Loading risky deposits...'

SELECT * FROM pg_temp._risky_deposits(NULL);

\prompt 'do you want to fail these deposits?', answer
\echo ''

SELECT * FROM pg_temp._risky_deposits(:'answer');

\pset pager on

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'risky_deposits');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
