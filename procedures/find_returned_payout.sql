/*Looks for returned payouts with reference number, name and bank account in Ledger, CSV and MT940 statements. Also looking for LHV and CITI returned payouts which have different reference number.*/

--EXAMPLES: 3855645276,4224908393,3704506155,2029808911,3798653319(only ledger atm)

\prompt '\nEnter BankWithdrawalID to find a returned payment: ' bankwithdrawalid 

\set QUIET ON
--For better readability \pset expanded ON. It is set back to AUTO at the end!
\pset expanded ON
\timing OFF

\echo '\n*******************'
\echo '*    STATEMENT    *'
\echo '*******************\n'

WITH payout_info AS(
   SELECT
      w.bankledgerid,
      w.bankwithdrawalid AS "reference",
      w.sendingbankaccountid AS "bankaccountid",
      w.datestamp :: DATE AS "date",
      w.currency AS "currency",
      CASE
         WHEN (w.amount - (100 * cr.ask)) < 0 THEN 0
         ELSE (w.amount - (100 * cr.ask))
      END AS "min_amount",
      w.amount AS "max_amount",
      w.name AS "name",
      w.toaccountnumber AS "accountnumber",
      ba.ecosysaccount AS "bank",
      CASE
         WHEN (tba.clearinghouseid = 44) THEN '1 month' :: INTERVAL
         ELSE '14 days' :: INTERVAL
      END AS "search_period"
   FROM
      bankwithdrawals w
      LEFT JOIN bankaccounts ba ON ba.bankaccountid = w.sendingbankaccountid
      LEFT JOIN transferbankaccounts tba ON tba.transferbankaccountid = w.transferbankaccountid
      LEFT JOIN currencypairs cp ON ( w.currency = cp.quotecurrency AND cp.basecurrency = 'EUR')
      LEFT JOIN currencyexchangerates cr ON (cp.currencypairid = cr.currencypairid)
   WHERE
      bankwithdrawalid = :'bankwithdrawalid'
),
bank_reference_number AS (
   -- Add new case for each bank which generate new bankreferencenumber (CSV statement)
   SELECT
      CASE
         -- LHV ESTONIA
         WHEN ecosysaccount ilike 'CLIENT_FUNDS_ESTONIA_LHVB%' THEN ( SUBSTRING( array_to_string(textcolumns, ','), POSITION( 'AcctSvcrRef:' IN array_to_string(textcolumns, ',') ) + 15, 30 ) )
         ELSE NULL
      END AS "bank_reference_number"
   FROM
      ledger.view_all_rows
   WHERE
      bankledgerid = ( SELECT bankledgerid FROM payout_info )

   UNION

   -- Add new case for each bank which generate new bankreferencenumber (MT940  statement)
   SELECT
      CASE
         -- CITI UK
         WHEN ecosysaccount ilike ('CLIENT_FUNDS_UNITED_KINGDOM_CITI%') THEN 
            CASE 
               WHEN ( POSITION('NMSC' IN array_to_string(textcolumns, ',')) ) = 0 THEN ( SUBSTRING( array_to_string(textcolumns, ','), ( POSITION('NTRF' IN array_to_string(textcolumns, ',')) + 4 ), 10 ) )
               ELSE ( SUBSTRING( array_to_string(textcolumns, ','), ( POSITION('NMSC' IN array_to_string(textcolumns, ',')) + 4 ), ( POSITION('//' IN array_to_string(textcolumns, ',')) - POSITION('NMSC' IN array_to_string(textcolumns, ',')) -4 ) ) )
            END
         -- SEB GERMANY
         WHEN ecosysAccount ILIKE ('CLIENT_FUNDS_GERMANY_ESSE%') THEN SUBSTRING( array_to_string(textcolumns, ','), POSITION('FRA' IN array_to_string(textcolumns, ',')) + 4, 11 )
         ELSE NULL
      END AS "bank_reference_number"
   FROM
      mt94xparser.View_All_Rows
   WHERE
      BankLedgerID = ( SELECT bankledgerid FROM payout_info )
)
SELECT
   'CSV' AS "statement",
   ledgerrowid,
   ecosysaccount,
   currency,
   amount,
   balancedate,
   datecolumn1 AS "valuedate",
   textcolumns,
   bankledgerid
FROM
   ledger.view_all_rows
WHERE
   ecosysAccount = ( SELECT "bank" FROM payout_info)
   AND balanceDate BETWEEN ((SELECT "date" FROM payout_info)) AND ((SELECT "date" FROM payout_info) + (SELECT "search_period" FROM payout_info))
   AND currency = (SELECT "currency" FROM payout_info)
   AND amount BETWEEN (SELECT "min_amount" FROM payout_info) AND (SELECT "max_amount" FROM payout_info)
   AND (
         (array_to_string(textcolumns,',') ilike '%' || (SELECT "accountnumber" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "name" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "reference" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "bank_reference_number" FROM bank_reference_number) || '%')
      )

UNION

SELECT
   'MT940' AS "statement",
   statementlineid,
   ecosysaccount,
   currency,
   amount,
   balancedate,
   valuedate,
   textcolumns,
   bankledgerid
FROM
   mt94xparser.View_All_Rows
WHERE
   ecosysAccount = ( SELECT "bank" FROM payout_info)
   AND valuedate BETWEEN ((SELECT "date" FROM payout_info)) AND ((SELECT "date" FROM payout_info) + (SELECT "search_period" FROM payout_info))
   AND currency = (SELECT "currency" FROM payout_info)
   AND amount BETWEEN (SELECT "min_amount" FROM payout_info) AND (SELECT "max_amount" FROM payout_info)
   AND (
         (array_to_string(textcolumns,',') ilike '%' || (SELECT "accountnumber" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "name" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "reference" FROM payout_info) || '%')
      OR (array_to_string(textcolumns,',') ilike '%' || (SELECT "bank_reference_number" FROM bank_reference_number) || '%')
      );

\echo '*******************'
\echo '*   BANK LEDGER   *'
\echo '*******************\n'

WITH payout_info AS(
   SELECT
      w.bankledgerid,
      w.bankwithdrawalid AS "reference",
      w.sendingbankaccountid AS "bankaccountid",
      w.datestamp :: DATE AS "date",
      w.currency AS "currency",
      CASE
         WHEN (w.amount - (100 * cr.ask)) < 0 THEN 0
         ELSE (w.amount - (100 * cr.ask))
      END AS "min_amount",
      w.amount AS "max_amount",
      w.name AS "name",
      w.toaccountnumber AS "accountnumber",
      ba.ecosysaccount AS "bank",
      CASE
         WHEN (tba.clearinghouseid = 44) THEN '1 month' :: INTERVAL
         ELSE '14 days' :: INTERVAL
      END AS "search_period"
   FROM
      bankwithdrawals w
      LEFT JOIN bankaccounts ba ON ba.bankaccountid = w.sendingbankaccountid
      LEFT JOIN transferbankaccounts tba ON tba.transferbankaccountid = w.transferbankaccountid
      LEFT JOIN currencypairs cp ON ( w.currency = cp.quotecurrency AND cp.basecurrency = 'EUR')
      LEFT JOIN currencyexchangerates cr ON (cp.currencypairid = cr.currencypairid)
   WHERE
      bankwithdrawalid = :'bankwithdrawalid'
),
bank_reference_number AS (
   -- Add new case for each bank which generate new bankreferencenumber (CSV statement)
   SELECT
      CASE
         -- LHV ESTONIA
         WHEN ecosysaccount ilike 'CLIENT_FUNDS_ESTONIA_LHVB%' THEN ( SUBSTRING( array_to_string(textcolumns, ','), POSITION( 'AcctSvcrRef:' IN array_to_string(textcolumns, ',') ) + 15, 30 ) )
         ELSE NULL
      END AS "bank_reference_number"
   FROM
      ledger.view_all_rows
   WHERE
      bankledgerid = ( SELECT bankledgerid FROM payout_info )

   UNION

   -- Add new case for each bank which generate new bankreferencenumber (MT940  statement)
   SELECT
      CASE
         -- CITI UK
         WHEN ecosysaccount ilike ('CLIENT_FUNDS_UNITED_KINGDOM_CITI%') THEN 
            CASE 
               WHEN ( POSITION('NMSC' IN array_to_string(textcolumns, ',')) ) = 0 THEN ( SUBSTRING( array_to_string(textcolumns, ','), ( POSITION('NTRF' IN array_to_string(textcolumns, ',')) + 4 ), 10 ) )
               ELSE ( SUBSTRING( array_to_string(textcolumns, ','), ( POSITION('NMSC' IN array_to_string(textcolumns, ',')) + 4 ), ( POSITION('//' IN array_to_string(textcolumns, ',')) - POSITION('NMSC' IN array_to_string(textcolumns, ',')) -4 ) ) )
            END
         -- SEB GERMANY
         WHEN ecosysAccount ILIKE ('CLIENT_FUNDS_GERMANY_ESSE%') THEN SUBSTRING( array_to_string(textcolumns, ','), POSITION('FRA' IN array_to_string(textcolumns, ',')) + 4, 11 )
         ELSE NULL
      END AS "bank_reference_number"
   FROM
      mt94xparser.View_All_Rows
   WHERE
      BankLedgerID = ( SELECT bankledgerid FROM payout_info )
)
SELECT
   *
FROM
   view_bank_ledger
WHERE
   bankaccountid = (SELECT "bankaccountid" FROM payout_info) 
   AND date BETWEEN (SELECT "date" FROM payout_info) AND (SELECT "date" FROM payout_info) + (SELECT "search_period" FROM payout_info)
   AND currency = (SELECT "currency" FROM payout_info)
   AND amount BETWEEN (SELECT "min_amount" FROM payout_info) AND (SELECT "max_amount" FROM payout_info)
   AND (
         (text ilike '%' || (SELECT "accountnumber" FROM payout_info) || '%')
      OR (text ilike '%' || (SELECT "name" FROM payout_info) || '%')
      OR (text ilike '%' || (SELECT "reference" FROM payout_info) || '%')
      OR (text ilike '%' || (SELECT "bank_reference_number" FROM bank_reference_number) || '%') );

\echo '*******************'
\echo '*      OTHER      *'
\echo '*******************\n'

WITH payout_info AS (
   SELECT
      w.bankledgerid,
      w.bankwithdrawalid AS "reference",
      w.sendingbankaccountid AS "bankaccountid",
      w.datestamp :: DATE AS "date",
      w.currency AS "currency",
      CASE
         WHEN (w.amount - (100 * cr.ask)) < 0 THEN 0
         ELSE (w.amount - (100 * cr.ask))
      END AS "min_amount",
      w.amount AS "max_amount",
      w.name AS "name",
      w.toaccountnumber AS "accountnumber",
      ba.ecosysaccount AS "bank",
      CASE
         WHEN (tba.clearinghouseid = 44) THEN '1 month' :: INTERVAL
         ELSE '14 days' :: INTERVAL
      END AS "search_period"
   FROM
      bankwithdrawals w
      LEFT JOIN bankaccounts ba ON ba.bankaccountid = w.sendingbankaccountid
      LEFT JOIN transferbankaccounts tba ON tba.transferbankaccountid = w.transferbankaccountid
      LEFT JOIN currencypairs cp ON ( w.currency = cp.quotecurrency AND cp.basecurrency = 'EUR')
      LEFT JOIN currencyexchangerates cr ON (cp.currencypairid = cr.currencypairid)
   WHERE
      bankwithdrawalid = :'bankwithdrawalid'
)
SELECT
   count(*) AS "POSSIBLE RETURNS",
   'SELECT * FROM view_bank_ledger WHERE bankaccountid = ' || (SELECT "bankaccountid" FROM payout_info) || ' AND currency = ' || '''' || (SELECT "currency" FROM payout_info) || '''' || ' AND date BETWEEN ' || '''' || ((SELECT "date" FROM payout_info)) || '''' || ' AND ' || '''' || ((SELECT "date" FROM payout_info) + (SELECT "search_period" FROM payout_info)) || '''' || ' AND amount = ' || (SELECT "max_amount" FROM payout_info) || ' AND claimable;' AS "QUERY TO RUN"
FROM
   view_bank_ledger
WHERE
   bankaccountid = (SELECT "bankaccountid" FROM payout_info)
   AND date BETWEEN (SELECT "date" FROM payout_info) AND ((SELECT "date" FROM payout_info) + (SELECT "search_period" FROM payout_info))
   AND currency = (SELECT "currency" FROM payout_info)
   AND amount = (SELECT "max_amount" FROM payout_info)
   AND claimable;

\echo 'ALWAYS DOUBLE CHECK THE RESULT!\n'

\pset expanded AUTO
\timing ON