/* Info for merchant to claim bankledger row - via QuickText in SalesForce */
\echo test
\echo '\n'
\prompt 'Please enter the BankLedgerID', bankledgerid
​
\set QUIET ON
​
\pset expanded off
​
\x ON
​
WITH transactionDetails AS (
   SELECT
      bankledger.bankledgerid,
      bankledger.bankaccountid,
      bankledger.amount,
      COALESCE( bankledger.recorddate, bankledger.transactiondate ) AS date,
      bankledger.glueid,
      Bankledger.statementtext
   FROM
      bankledger
   WHERE
      bankledgerid = :'bankledgerid'
)
SELECT
   bankledgerid,
   CASE
      WHEN ((CURRENT_DATE - transactiondate) < 90) THEN 'OK'
      WHEN ((CURRENT_DATE - transactiondate) BETWEEN 90 AND 180) THEN CONCAT((CURRENT_DATE - transactiondate),' DAYS OLD! CLAIMABLE BY TRUSTLY SUPPORT!')
      ELSE CONCAT((CURRENT_DATE - transactiondate),' DAYS OLD! CONTACT AM!')
   END AS "date_check",
   COUNT(*) over() AS bankledger_transactions,
   COALESCE( NULLIF(mt.total, 0), NULLIF(csv.total, 0) ) AS statement_transactions,
   CASE
      WHEN (
         (COUNT(*) over()) > COALESCE( NULLIF(mt.total, 0), NULLIF(csv.total, 0) )
      ) THEN 'ATTENTION DUPLICATES!'
      ELSE 'NONE DETECTED'
   END AS duplicates_check,
   CASE
      WHEN (
         (
            (
               bl.processed = 0
               AND is_safe_deposit(bl.bankledgerid) IS TRUE
            )
            OR (
               bl.unclaimedat IS NOT NULL
               AND bl.bookedasrevenueat IS NULL
            )
         )
         AND (ba.allowclaim = 1)
      ) THEN 'YES'
      ELSE 'NO'
   END AS claimable,
   processedas,
   describe_ledger_row(bl.bankledgerid) AS "ledger_info"
FROM
   bankledger bl
   JOIN bankaccounts ba ON ba.BankaccountID = bl.bankaccountid
   LEFT JOIN LATERAL(
      SELECT
         COUNT(*) AS "total"
      FROM
         MT94xparser.statementlines
      WHERE
         accountidentificationid IN (
            SELECT
               accountidentificationid
            FROM
               MT94xparser.accountIdentifications
            WHERE
               accountidentification IN (
                  SELECT
                     accountidentification
                  FROM
                     bankaccounts
                  WHERE
                     bankaccountid = bl.bankaccountid
               )
         )
         AND amount = bl.amount
         AND balancedate = COALESCE(bl.recorddate, bl.transactiondate)
   ) AS mt ON TRUE
   LEFT JOIN LATERAL(
      SELECT
         COUNT(*) AS "total"
      FROM
         ledger.rows
      WHERE
         ledgeraccountID IN (
            SELECT
               ledgeraccountid
            FROM
               ledger.accounts
            WHERE
               accountidentification IN (
                  SELECT
                     ecosysaccount
                  FROM
                     bankaccounts
                  WHERE
                     bankaccountid = bl.bankaccountid
               )
         )
         AND amount = bl.amount
         AND balancedate = COALESCE(bl.recorddate, bl.transactiondate)
   ) AS csv ON TRUE
WHERE
   bl.bankaccountid = ( SELECT bankaccountid FROM transactionDetails )
   AND bl.amount = ( SELECT amount FROM transactionDetails )
   AND COALESCE(bl.recorddate, bl.transactiondate) = ( SELECT date FROM transactionDetails )
GROUP BY
   1,2,4,6,7
ORDER BY
   bl.bankledgerid = :'bankledgerid' DESC
LIMIT 1;
​
\echo 'Claiming Tool Details:'
​
SELECT
  ba.currency AS "Currency",
  CONCAT(
    ch.name,
    ': ',
    b.longname,
    ', ',
    bn.banknumber,
    '-',
    ba.accountnumber,
    ' ',
    ba.currency
  ) AS "Bank Account",
  l.transactiondate AS "Date",
  l.amount AS "Amount"
FROM
  bankledger l
  LEFT JOIN bankaccounts ba ON (l.bankaccountid = ba.bankaccountid)
  LEFT JOIN banknumbers bn ON (ba.banknumberid = bn.banknumberid)
  LEFT JOIN banks b ON (bn.bankid = b.bankid)
  JOIN clearinghouses ch ON (ch.clearinghouseid = bn.clearinghouseid)
WHERE
  l.bankledgerid = :'bankledgerid';
​
\echo 'Please double check your findings. Compare bankledger candidates to what we have in our statements (MT or CSV)'
