--
CREATE OR REPLACE FUNCTION pg_temp.UserAccessLog(_Procedure text)
   RETURNS void
   LANGUAGE plpgsql
AS $function$
DECLARE
  _Procedure text;
BEGIN

INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), _Procedure);
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV

END;
$function$;
