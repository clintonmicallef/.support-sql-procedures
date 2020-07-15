/* Function used to copy user activity run by every procedures in repo, into an export temp table (making sure table is clean before not to copy duplicates from previous activity) */
CREATE OR REPLACE FUNCTION pg_temp.user_log_function(_username text, _datestamp timestamp, _procedure text)
  RETURNS void
  LANGUAGE plpgsql
AS $function$
    BEGIN
    DELETE FROM supportsql_userlogexport;
    INSERT INTO SupportSQL_UserLogExport VALUES (_username, _datestamp, _procedure);
    END
$function$;
