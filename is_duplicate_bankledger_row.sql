--Checks whether bankledgerID is a duplicate or not.
--To be used similar as Is_Correct_GlueID()

CREATE OR REPLACE FUNCTION pg_temp.is_duplicate_bankledger_row(_checkBankledgerID bigint)
  RETURNS boolean
  LANGUAGE sql
  STABLE STRICT

AS $function$

DECLARE
_BankledgerID bigint;
_BankAccountID integer;
_Amount numeric;
_Statementtext text;
_Transactiondate date;
_Valuedate date;
_Recorddate date;
_GlueID bigint;
_StatementlineID bigint;
_LedgerrowID bigint;
_swiftxmlstatementlineid bigint;

SELECT Bankledger.BankledgerID,
       Bankledger.BankAccountID,
       Bankledger.Amount,
       Bankledger.StatementText,
       Bankledger.Transactiondate,
       Bankledger.Valuedate,
       Bankledger.Recorddate,
       Bankledger.GlueID,
       Bankledger.StatementlineID,
       Bankledger.LedgerrowID,
       Bankledger.swiftxmlstatementlineid
  INTO _BankledgerID,
       _BankAccountID,
       _Amount,
       _Statementtext,
       _Transactiondate,
       _Valuedate,
       _Recorddate,
       _GlueID,
       _StatementlineID,
       _LedgerrowID,
       _swiftxmlstatementlineid
  FROM Bankledger
 WHERE Bankledger.BankledgerID = _checkBankledgerID

SELECT EXISTS(
  SELECT 1
    FROM bankledger duplicatescheck
   WHERE duplicatescheck.bankaccountid = _BankAccountID
     AND duplicatescheck.BankledgerID != _BankledgerID
     AND duplicatescheck.amount = _Amount
     AND (duplicatescheck.transactiondate = _Transactiondate OR duplicatescheck.valuedate = _valueDate OR duplicatescheck.recorddate = _recorddate)
     AND (duplicatescheck.glueID IS NULL OR (duplicatescheck.glueID = substring(_Statementtext, '[0-9]{10}')::bigint) OR duplicatescheck.glueID = _GlueID)
     AND (
       CASE
        WHEN _StatementLineID IS NOT NULL THEN
          (CASE WHEN _StatementLineID IS NULL THEN duplicatescheck.StatementlineID IS NOT NULL ELSE duplicatescheck.statementlineID IS NULL END)
        WHEN _LedgerrowID IS NOT NULL THEN
          (CASE WHEN _LedgerrowID IS NULL THEN duplicatescheck.LedgerrowID IS NOT NULL ELSE duplicatescheck.LedgerrowID IS NULL END)
        WHEN _swiftxmlstatementlineid IS NOT NULL THEN
          (CASE WHEN _swiftxmlstatementlineid IS NULL THEN duplicatescheck.swiftxmlstatementlineid IS NOT NULL ELSE duplicates.swiftxmlstatementlineid IS NULL END)
        ELSE NULL END)
  )

AS $function$
