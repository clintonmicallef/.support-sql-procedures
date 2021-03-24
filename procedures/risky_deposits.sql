/* (only) Calls the view function to show risky deposits */

\set QUIET ON

\pset expanded off

SELECT * FROM pg_temp.secondline_view_risky_deposits_upd();


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'risky_deposits');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
