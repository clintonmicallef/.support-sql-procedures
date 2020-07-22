SELECT (CASE  WHEN (SELECT user) = 'benjaminschembri' THEN (
  SELECT *
    FROM Users
   LIMIT 1
)
ELSE 'Not Authorised' END)
;



CREATE OR REPLACE FUNCTION pg_temp.repository_user_validation()
   RETURNS text
   LANGUAGE plpgsql
   STABLE
AS $function$

DECLARE
_loggedinuser text;
_SQL varchar;

BEGIN

SELECT user INTO _loggedinuser;

IF _loggedinuser = 'charles' -- IN ('artiomturkov', 'benjaminschembri', 'dimitriossliakas')
  THEN
      RETURN 'true';
ELSE
  RETURN 'false';
END IF;

END;
$function$;
