/* Info for merchant to claim bankledger row - via QuickText in SalesForce */

\prompt 'Please enter the BankLedgerID', bankledgerid

\set QUIET ON

\pset expanded off

WITH BankledgerCandidateDetails AS(
  SELECT BankLedger.BankledgerID,
         BankLedger.bankaccountid,
         BankLedger.amount,
         COALESCE(BankLedger.Transactiondate,BankLedger.Recorddate) AS date,
         BankLedger.GlueID,
         Bankledger.Statementtext
  FROM BankLedger
 WHERE BankLedger.bankledgerid = :'bankledgerid'
  )
  SELECT BankledgerId,
         AMount,
         transactiondate,
         GlueID,
         Processed::boolean,
         Processedas,
         SUM(COUNT(*)) over() AS bankledgercandidates,
         COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)) AS StatementTransactions,
         (CASE WHEN ((SUM(COUNT(*)) over()) > COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)))  THEN 'ATTENTION DUPLICATES!' ELSE 'NONE DETECTED' END) AS Duplicates_CHeck,
         CASE WHEN ((bankledger.processed = 0 AND is_safe_deposit(bankledger.bankledgerid) IS TRUE) OR (bankledger.unclaimedat IS NOT NULL AND bankledger.bookedasrevenueat IS NULL)) AND (BankAccounts.allowclaim = 1) THEN 'YES' ELSE 'NO' END AS Claimable
    FROM bankledger
    JOIN BankAccounts ON Bankaccounts.BankaccountID = Bankledger.bankaccountid
    LEFT JOIN LATERAL(
      SELECT SUM(COUNT(*)) over() as COUNT
        FROM MT94xparser.statementlines
       WHERE accountidentificationID IN (SELECT accountidentificationid FROM MT94xparser.accountIdentifications WHERE AccountIdentification IN (SELECT Accountidentification FROM bankaccounts where bankaccountid = bankledger.bankaccountid))
         AND amount = bankledger.amount
         AND balancedate = bankledger.transactiondate
         AND (glueid = bankledger.glueID OR glueid IS NULL)
    ) AS MTStatements ON TRUE
    LEFT JOIN LATERAL(
      SELECT SUM(COUNT(*)) over() as COUNT
        FROM Ledger.rows
       WHERE ledgeraccountID IN (SELECT ledgeraccountid from ledger.accounts where accountidentification IN (SELECT ecosysaccount from bankaccounts where bankaccountid = bankledger.bankaccountid))
         AND amount = bankledger.amount
         AND balancedate = bankledger.transactiondate
         AND (reference = bankledger.glueID OR reference IS NULL)
    ) AS CSVStatements ON TRUE
   WHERE bankledger.bankaccountid IN (SELECT bankaccountid FROM BankledgerCandidateDetails)
     AND amount IN (SELECT amount FROM BankledgerCandidateDetails)
     AND Transactiondate IN (SELECT date FROM BankledgerCandidateDetails)
     AND (
         ((SELECT GLUEID FROM BankledgerCandidateDetails) IS NOT NULL AND Bankledger.GlueID IN (SELECT GLUEID FROM BankledgerCandidateDetails))
      OR ((SELECT GLUEID FROM BankledgerCandidateDetails) IS NULL AND Bankledger.GLUEID IS NULL)
      OR ((SELECT GLUEID FROM BankledgerCandidateDetails) IS NOT NULL AND bankledger.statementtext::text ILIKE '%' || (SELECT GlueID from BankledgerCandidateDetails) || '%')
      OR ((SELECT GLUEID FROM BankledgerCandidateDetails) IS NULL AND (SELECT statementtext from BankledgerCandidateDetails) ILIKE '%' || Bankledger.glueID || '%')
         )
   GROUP BY 1,2,3,4,5,6,8,10
;

\echo 'Please double check your findings. Compare bankledger candidates to what we have in our statements (MT or CSV)'
\echo '\n'
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
  AND EXISTS (
    SELECT 1
      FROM (
        WITH BankledgerCandidateDetails AS(
          SELECT BankLedger.BankledgerID,
                 BankLedger.bankaccountid,
                 BankLedger.amount,
                 COALESCE(BankLedger.Transactiondate,BankLedger.Recorddate) AS date,
                 BankLedger.GlueID
          FROM BankLedger
         WHERE BankLedger.bankledgerid = :'bankledgerid'
          )
          SELECT BankledgerId,
                 AMount,
                 transactiondate,
                 GlueID,
                 Processed::boolean,
                 Processedas,
                 SUM(COUNT(*)) over() AS bankledgercandidates,
                 COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)) AS StatementTransactions,
                 (CASE WHEN ((SUM(COUNT(*)) over()) > COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)))  THEN 'ATTENTION DUPLICATES!' ELSE 'NONE DETECTED' END) AS Duplicates_CHeck,
                 CASE WHEN ((bankledger.processed = 0 AND is_safe_deposit(bankledger.bankledgerid) IS TRUE) OR (bankledger.unclaimedat IS NOT NULL AND bankledger.bookedasrevenueat IS NULL)) AND (BankAccounts.allowclaim = 1) THEN 'YES' ELSE 'NO' END AS Claimable
            FROM bankledger
            JOIN BankAccounts ON Bankaccounts.BankaccountID = Bankledger.bankaccountid
            LEFT JOIN LATERAL(
              SELECT SUM(COUNT(*)) over() as COUNT
                FROM MT94xparser.statementlines
               WHERE accountidentificationID IN (SELECT accountidentificationid FROM MT94xparser.accountIdentifications WHERE AccountIdentification IN (SELECT Accountidentification FROM bankaccounts where bankaccountid = bankledger.bankaccountid))
                 AND amount = bankledger.amount
                 AND balancedate = bankledger.transactiondate
                 AND (glueid = bankledger.glueID OR glueid IS NULL)
            ) AS MTStatements ON TRUE
            LEFT JOIN LATERAL(
              SELECT SUM(COUNT(*)) over() as COUNT
                FROM Ledger.rows
               WHERE ledgeraccountID IN (SELECT ledgeraccountid from ledger.accounts where accountidentification IN (SELECT ecosysaccount from bankaccounts where bankaccountid = bankledger.bankaccountid))
                 AND amount = bankledger.amount
                 AND balancedate = bankledger.transactiondate
                 AND (reference = bankledger.glueID OR reference IS NULL)
            ) AS CSVStatements ON TRUE
           WHERE bankledger.bankaccountid IN (SELECT bankaccountid FROM BankledgerCandidateDetails)
             AND amount IN (SELECT amount FROM BankledgerCandidateDetails)
             AND Transactiondate IN (SELECT date FROM BankledgerCandidateDetails)
             AND (Bankledger.GlueID IN (SELECT GLUEID FROM BankledgerCandidateDetails) OR Bankledger.GLUEID IS NULL)
           GROUP BY 1,2,3,4,5,6,8,10
      ) BankledgerCandidatestoclaim
    WHERE BankledgerCandidatestoclaim.duplicates_check = 'NONE DETECTED'
      AND BankledgerCandidatestoclaim.claimable = 'YES'
    )
;

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'merchant_claiming_procedure');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
