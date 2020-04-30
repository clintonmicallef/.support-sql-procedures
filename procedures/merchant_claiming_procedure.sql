/* Info for merchant to claim bankledger row - via QuickText in SalesForce */

\prompt 'Please enter the BankLedgerID', bankledgerid

\set QUIET ON

\timing OFF

\pset expanded off

\echo '\n'
\echo 'BankLedger row Info:'

WITH cte(bankaccountid, amount, date) AS (
  SELECT
    bankaccountid,
    amount,
    COALESCE(Transactiondate,Recorddate) AS date
  FROM BankLedger
  WHERE
    bankledgerid = :'bankledgerid'
  )
  SELECT
    count(*) as "Payments in Ledger",
    CASE
      WHEN ((bankledger.processed = 0 AND is_safe_deposit(bankledger.bankledgerid) IS TRUE) OR (bankledger.unclaimedat IS NOT NULL AND bankledger.bookedasrevenueat IS NULL)) AND (BankAccounts.allowclaim = 1)
      THEN 'YES'
      ELSE 'NO'
    END AS "Claimable by the merchant"
  FROM BankLedger
  JOIN BankAccounts ON BankAccounts.BanKAccountID = BankLedger.BankAccountID
  WHERE
    BankLedger.bankaccountid = (
      SELECT
        bankaccountid
      FROM cte
    )
    AND amount = (
      SELECT
        amount
      FROM cte
    )
    AND COALESCE(transactiondate, recorddate) = (
      SELECT
        date
      FROM cte
    )
    AND (Processed = 0 OR Processedas::text = 'UNCLAIMED')
   GROUP  BY 2
;

\echo 'Claiming Tool Details:'

SELECT
  ba.currency as "Currency",
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
  ) as "Bank Account",
  COALESCE(l.transactiondate, l.recorddate) as "Date",
  l.amount as "Amount"
FROM BankLedger l
LEFT JOIN bankaccounts ba ON (l.bankaccountid = ba.bankaccountid)
LEFT JOIN banknumbers bn ON (ba.banknumberid = bn.banknumberid)
LEFT JOIN banks b ON (bn.bankid = b.bankid)
JOIN clearinghouses ch ON (ch.clearinghouseid = bn.clearinghouseid)
WHERE
  l.bankledgerid = :'bankledgerid'
;

\timing ON

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'merchant_claiming_procedure.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
