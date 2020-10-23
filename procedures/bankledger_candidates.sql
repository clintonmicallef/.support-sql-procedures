/* Find bankledger candidates for missing deposits  */

\prompt 'Please enter the ecosysaccount', account
\prompt 'Please enter the amount', amount
\prompt 'Please enter the date', tdate
\prompt 'Please enter a glueID/reference or press enter if none is available', reference

\set QUIET ON

\pset expanded off

SELECT SUM(COUNT(*)) over() AS In_bankldger,
       BankledgerId,
       AMount,
       transactiondate,
       GlueID,
       Processed::boolean,
       Processedas,
       COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)) AS IN_Statements,
       (CASE WHEN ((SUM(COUNT(*)) over()) > COALESCE(NULLIF(MTStatements.COUNT,0), NULLIF(CSVSTATEMENTS.COUNT,0)))  THEN 'ATTENTION DUPLICATES!' ELSE 'NONE DETECTED' END) AS Duplicates_CHeck
  FROM bankledger
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
 WHERE bankaccountid IN (SELECT bankaccountid from bankaccounts where ecosysaccount = :'account')
   AND amount = :'amount'
   AND Transactiondate = :'tdate'
   AND ((SELECT CASE WHEN NULLIF(:'reference','') IS NOT NULL THEN Bankledger.GlueID::text = :'reference' ELSE Bankledger.GlueID IS NULL END) OR Bankledger.GLUEID IS NULL)
 GROUP BY 2,3,4,5,6,7,8
;


\echo 'Please double check your findings. Compare bankledger candidates to what we have in our statements (MT or CSV)'
\echo 'If the bankledger is verified for a claim, please run :merchant_claiming_procedure'


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'bankledger_candidates');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
