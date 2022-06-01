--2nd Line function to view unclaimed deposits meant for bondora 

--- To explore whether this can be used for all unmapped transactions

CREATE OR REPLACE FUNCTION pg_temp.view_bondora_unclaimed_to_refund()
   RETURNS TABLE(datestamp timestamp with time zone, banknumber text, accountnumber text, sender_name text, statementlineid bigint, bankledgerid bigint, amount numeric, glueid bigint, enduserid text)
   LANGUAGE plpgsql
   STABLE
AS $function$

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

    RETURN QUERY
       SELECT  bankledger.datestamp,
        (Parse_BIC_IBAN_Account_Number(SUBSTRING(accountownerinformation::text, 'EE[0-9]{18}'))).banknumber::text,
        SUBSTRING(accountownerinformation::text, 'EE[0-9]{18}') as accountnumber,
        REGEXP_REPLACE(REGEXP_REPLACE(SPLIT_PART(accountownerinformation::text,',',3),'"',''),'"','') as Sender_name,
        bankledger.statementlineid,
        bankledger.bankledgerid,
        bankledger.amount,
        bankledger.glueid,
        orders.enduserid
        FROM bankledger
        JOIN transfers ON transfers.transferid = bankledger.glueid AND transfertypeid = 1
        JOIN orders ON orders.orderid = transfers.orderid
        JOIN mt94xparser.statementlines ON statementlines.statementlineid = bankledger.statementlineid
        WHERE   bankledger.bankaccountid = 113 -- Swedbank Estonia
        AND     bankledger.amount > 0
        AND     (bankledger.processed = 0 OR bankledger.processedas = 'UNCLAIMED')
        AND     bankledger.glueid IS NOT NULL
        AND     bankledger.datestamp >= NOW()-'7 days'::interval
        AND     transfers.userid = get_userid('bondora')
        AND     NOT EXISTS(
            SELECT 1
            FROM bankledger duplicatescheck
            WHERE duplicatescheck.bankaccountid = bankledger.bankaccountid
                AND duplicatescheck.BankledgerID != Bankledger.BankLedgerID
                AND duplicatescheck.amount = bankledger.amount
                AND duplicatescheck.transactiondate = bankledger.transactiondate
                AND (duplicatescheck.glueID IS NULL OR (duplicatescheck.glueID = substring(Bankledger.Statementtext, '[0-9]{10}')::bigint))
                AND (CASE WHEN bankledger.statementlineid IS NULL THEN duplicatescheck.statementlineID IS NOT NULL ELSE duplicatescheck.statementlineID IS NULL END)
        )
        ORDER BY 1 ASC
        ;


RETURN;
END;
$function$;
