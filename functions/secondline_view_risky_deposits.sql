--2nd Line function to view risky deposits and fail them according to input by agent
--Related to procedure:

CREATE OR REPLACE FUNCTION pg_temp.secondline_view_risky_deposits()
   RETURNS TABLE(datestamp timestamp(0), orderid bigint, username character varying, enduserid text, entrystepid integer, fromclearinghouse character varying, frombank text, risky boolean, amount numeric, currency character(3), missingdays integer, avgdays integer, referencetext text, toclearinghouse character varying, tobank text, ecosysaccount character varying, transferid bigint, extaccholder boolean, totalfrombank bigint, totaltobank bigint)
   LANGUAGE plpgsql
   STABLE
AS $function$

DECLARE
_loggedinuser text;

BEGIN

SELECT user INTO _loggedinuser;

IF _loggedinuser IN ('artiomturkov', 'benjaminschembri', 'dimitriossliakas')
  THEN RETURN QUERY
       WITH unsettled AS(
       SELECT orders.orderid,
                   users.username,
                   orders.enduserid,
                   orders.datestamp,
                   orders.entrystepid,
                   transfers.amount,
                   transfers.currency,
                   bankordertransfers.totransferbankaccountid,
                   transferstates.name AS transferstate,
                   bankordertransfers.referencetext,
                   fromtransferbankaccount.kycdata,
                   totransferbankaccount.kycdata::json ->> 'bankcode'::text AS tobank,
                   totransferbankaccount.banknumber AS tobanknumber,
                   totransferbankaccount.accountnumber AS toaccountnumber,
                   totransferbankaccount.clearinghouseid AS toclearinghouseid,
                   transfers.transferid,
                   fromtransferbankaccount.clearinghouseid AS fromclearinghouseid,
           /*NEW*/ bankaccounts.EcoSysAccount,
           /*NEW*/ bankaccounts.bankaccountid,
           /*NEW*/ bankaccounts.externalaccountholder
              FROM (
                SELECT transfers_1.transferid,
                       transfers_1.amount,
                       transfers_1.currency,
                       transfers_1.transferstateid
                  FROM transfers transfers_1
                 WHERE (transfers_1.transferstateid = ANY (ARRAY[6, 13, 14]))
                   AND transfers_1.transfertypeid = 1
                   AND transfers_1.transfersystemid = 3
                   AND transfers_1.datestamp > (now() - '1 mons'::interval)
                OFFSET 0
              ) transfers
              JOIN bankordertransfers ON bankordertransfers.transferid = transfers.transferid
              JOIN orders ON orders.orderid = bankordertransfers.orderid
              JOIN users ON users.userid = orders.userid
              JOIN transferstates ON transferstates.transferstateid = transfers.transferstateid
              JOIN transferbankaccounts fromtransferbankaccount ON fromtransferbankaccount.transferbankaccountid = bankordertransfers.fromtransferbankaccountid
              JOIN transferbankaccounts totransferbankaccount ON totransferbankaccount.transferbankaccountid = bankordertransfers.totransferbankaccountid
              JOIN Bankaccounts on Bankaccounts.TransferBankAccountID=totransferbankaccount.TransferBankAccountID /*NEW*/
             WHERE users.username::text <> 'systemtester'::text
               AND orders.datestamp > (now() - '1 mons'::interval)
               AND (EXISTS (
                 SELECT 1
                   FROM transfers transfers_1
                  WHERE transfers_1.orderid = bankordertransfers.orderid
                    AND (transfers_1.transfertypeid = ANY (ARRAY[2, 3]))
                  )
                )
              ),
              avgsettlementtime AS(
                SELECT eventnamechainbalancessummary.entrystepid,
                       eventnamechainbalancessummary.totransferbankaccountid,
                       date_part('dow'::text, eventnamechainbalancessummary.orderdate) AS dow,
                       avg(eventnamechainbalancessummary.eventdate - eventnamechainbalancessummary.orderdate)::integer AS avgdays
                  FROM eventnamechainbalancessummary
                 WHERE eventnamechainbalancessummary.orderdate > (now() - '1 mon'::interval)
                   AND (eventnamechainbalancessummary.eventnamechainid IN (
                     SELECT eventnamechains.eventnamechainid
                       FROM eventnamechains
                      WHERE eventnamechains.name ~* ' (Settle|Debit|Refund)$'::text))
                      GROUP BY eventnamechainbalancessummary.entrystepid, eventnamechainbalancessummary.totransferbankaccountid, (date_part('dow'::text, eventnamechainbalancessummary.orderdate))
                ),
                FAIL as (
                  SELECT (to_char(unsettled.datestamp, 'YYYY-MM-DD HH24:MI'::text))::timestamp(0) AS datestamp,
                         unsettled.orderid,
                         unsettled.username,
                         unsettled.enduserid,
                         unsettled.entrystepid,
                         fromclearinghouse.name AS fromclearinghouse,
                         "overlay"(entrysteps.identifier, ''::text, 1, char_length('deposit.bank.'::text)) AS frombank,
                         entrysteps.risky,
                         unsettled.amount,
                         unsettled.currency,
                         now()::date - unsettled.datestamp::date AS missingdays,
                         avgsettlementtime.avgdays,
                         unsettled.referencetext,
                         toclearinghouse.name AS toclearinghouse,
                         COALESCE(unsettled.tobank, banks.name::text) AS tobank,
                         --(unsettled.tobanknumber || ' '::text) || unsettled.toaccountnumber AS toaccountnumber,
                         /*NEW*/ unsettled.EcoSysAccount,
                         --unsettled.kycdata,
                         unsettled.transferid,
                         (SELECT bankaccounts.externalaccountholder FROM bankaccounts WHERE bankaccounts.transferbankaccountid = unsettled.totransferbankaccountid ORDER BY (bankaccounts.currency = unsettled.currency) DESC LIMIT 1) AS extaccholder,
                         COUNT(entrysteps.identifier) OVER (PARTITION BY entrysteps.identifier) AS TotalFromBank,
                         COUNT(unsettled.EcoSysAccount) OVER (PARTITION BY unsettled.EcoSysAccount) AS TotalToBank
                    FROM unsettled
                    JOIN clearinghouses toclearinghouse ON toclearinghouse.clearinghouseid = unsettled.toclearinghouseid
                    JOIN clearinghouses fromclearinghouse ON fromclearinghouse.clearinghouseid = unsettled.fromclearinghouseid
                    JOIN entrysteps ON entrysteps.entrystepid = unsettled.entrystepid
                    JOIN ordersteps ON unsettled.orderid = ordersteps.orderid AND ordersteps.nextorderstepid IS NULL
                    JOIN ordersteptypes ON ordersteps.ordersteptypeid = ordersteptypes.ordersteptypeid
                    LEFT JOIN avgsettlementtime ON avgsettlementtime.entrystepid = unsettled.entrystepid AND avgsettlementtime.totransferbankaccountid = unsettled.totransferbankaccountid AND avgsettlementtime.dow = date_part('dow'::text, unsettled.datestamp)
                    LEFT JOIN banknumbers ON banknumbers.banknumber::text = unsettled.tobanknumber AND banknumbers.clearinghouseid = unsettled.toclearinghouseid
                    LEFT JOIN banks ON banks.bankid = banknumbers.bankid
                   WHERE (now()::date - unsettled.datestamp::date) > LEAST(7, avgsettlementtime.avgdays)
                   AND Unsettled.username = 'creditstar'
                     AND (now() - '12:00:00'::interval) > unsettled.datestamp
                     AND  ordersteptypes.name !~~ 'DepositSwedenNDEABibit.%'::text
             /*NEW*/ AND (now()::date - unsettled.datestamp::date)>=10
             /*NEW*/ AND unsettled.externalaccountholder!='t'
             /*NEW*/ AND unsettled.bankaccountid in (
                       SELECT bankaccountid
                         FROM BankAccounts
                        WHERE EXISTS (
                          SELECT 1
                            FROM BankLedger
                           WHERE TransactionDate >= current_date - 3
                             AND (CASE WHEN BankLedger.Datestamp >= current_date - 3 THEN TRUE END)
                             AND (LedgerRowID IS NOT NULL OR StatementLineID IS NOT NULL OR swiftxmlstatementlineid IS NOT NULL)
                             AND BankLedger.BankAccountID = BankAccounts.BankAccountID
                           )
                         ) /*NEW*/
                   ORDER BY unsettled.EcoSysAccount, unsettled.entrystepid, unsettled.datestamp ASC
                )
                SELECT fail.*
                  FROM fail;

ELSE RAISE EXCEPTION 'Unauthorised Access - 2nd line access only';
END IF;

RETURN;
END;
$function$;
