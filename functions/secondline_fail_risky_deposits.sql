--2nd Line function to view risky deposits and fail them according to input by agent
--Related to procedure: risky_deposits.sql

CREATE OR REPLACE FUNCTION pg_temp.secondline_fail_risky_deposits(_tofail text)
   RETURNS boolean
   LANGUAGE plpgsql

AS $function$

DECLARE
_loggedinuser text;
_transferID bigint;
_count bigint;

BEGIN

SELECT user INTO _loggedinuser;

IF _loggedinuser IN ('tomasvebr', 'benjaminschembri', 'dimitriossliakas')
  THEN
    IF _tofail = 'yes'
      THEN
        RAISE NOTICE 'Failing risky depsits...';

        SELECT TransferID, SUM(COUNT(*)) over()
          INTO _transferID,
               _count
          FROM pg_temp.secondline_view_risky_deposits()
         GROUP BY 1;

          IF _transferID IS NOT NULL
            THEN PERFORM fail_deposit_transfer(TransferID) FROM pg_temp.secondline_view_risky_deposits();
            RAISE NOTICE 'Failed % deposits', _count;
            RETURN TRUE;
          ELSE RAISE EXCEPTION 'No transfers to fail!';
          END IF;

    ELSIF _tofail = 'no'
      THEN RAISE NOTICE 'No actions taken. Exiting...';

    ELSE RAISE EXCEPTION 'Incorrect input. Enter ''yes'' to fail deposit transfers or ''no'' to exit';
    END IF;

ELSE RAISE EXCEPTION 'Unauthorised Access - 2nd line access only';
END IF;

RETURN FALSE;
END;
$function$;
