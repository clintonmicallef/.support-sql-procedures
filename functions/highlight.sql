-- Highlight text in a notice
CREATE OR REPLACE FUNCTION pg_temp.highlight(_text text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
_ESCReset text := E'\x1b[0m';
_ESCColor text := E'\x1b[32m'; -- green
BEGIN
RAISE NOTICE E'%', _ESCColor || _Text || _ESCReset;
RETURN;
END;
$function$;
