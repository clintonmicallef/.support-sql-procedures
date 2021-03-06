--2nd Line function to view risky deposits and fail them according to input by agent
--Related to procedure: risky_deposits.sql

CREATE OR REPLACE FUNCTION pg_temp.secondline_fail_risky_deposits(_tofail text)
RETURNS boolean
LANGUAGE plpgsql

AS $function$

DECLARE
_transferID bigint;
_count bigint;

BEGIN

  IF NOT EXISTS(
    SELECT 1
      FROM pg_auth_members
      JOIN pg_roles member ON member.oid = pg_auth_members.member
      JOIN pg_roles role ON role.oid=pg_auth_members.roleid
     WHERE role.rolname = 'support_second_line'
       AND member.rolname = session_user
     ) THEN
         RAISE EXCEPTION 'No Function access. 2ndline access only';
  END IF;

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

RETURN true;
END;
$function$;
