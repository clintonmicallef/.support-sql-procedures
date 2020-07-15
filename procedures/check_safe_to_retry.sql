/* Query returns TRUE or FALSE to whether BankWithdrawal is safe to be retried
   Checks the following bankwithdrawal whether it was confirmed and BankLedger Scans */

\prompt 'Please enter a BankWithdrawalID', bankwithdrawalID

\set QUIET ON

\pset expanded on

\echo "Run  :check_auto_retry_pending_payments  after this query"

WITH Values AS (
     SELECT BankWithdrawals.BankWithdrawalID,
            BankWithdrawals.SendingBankAccountID,
            ((FromBankNumbers.BankID = ToBankNumbers.BankID) OR BankWithdrawals.ToClearingHouseID = 7 /* IBAN */) AS SameBank,
            GREATEST(BankWithdrawals.TimestampExecutingUnfinished,BankWithdrawals.ModificationDate) AS ModificationDate,
            BankWithdrawals.ToClearingHouseID,
            BankWithdrawalStates.BankWithdrawalState,
            BankWithdrawals.TimestampExecuting,
            CASE WHEN BankWithdrawalStates.BankWithdrawalState IN ('QUEUED','PREPARING','PREPARED') THEN TRUE
                 WHEN BankWithdrawalStates.BankWithdrawalState IN ('EXECUTING','PENDING') AND BankWithdrawals.TimestampExecuting < GREATEST(BankWithdrawals.TimestampExecutingUnfinished,BankWithdrawals.ModificationDate) THEN NULL
                 ELSE FALSE END AS TrustNotExecuted
       FROM BankWithdrawals
      INNER JOIN BankWithdrawalStates ON (BankWithdrawalStates.BankWithdrawalStateID = BankWithdrawals.BankWithdrawalStateID)
      INNER JOIN BankAccounts ON (BankAccounts.BankAccountID = BankWithdrawals.SendingBankAccountID)
      INNER JOIN BankNumbers AS FromBankNumbers ON (FromBankNumbers.BankNumberID = BankAccounts.BankNumberID)
      INNER JOIN BankNumbers AS ToBankNumbers ON (ToBankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND ToBankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
      WHERE BankWithdrawals.BankWithdrawalID = :'bankwithdrawalID' -- CHANGE BANKWITHDRAWALID**********************<<-----
            ),
     MoreRecentConfirmedBankWithdrawalID AS (
     SELECT BankWithdrawals.BankWithdrawalID AS MoreRecentConfirmedBankWithdrawalID
     FROM BankWithdrawals
INNER JOIN BankAccounts ON (BankAccounts.BankAccountID = BankWithdrawals.SendingBankAccountID)
INNER JOIN BankNumbers AS FromBankNumbers ON (FromBankNumbers.BankNumberID = BankAccounts.BankNumberID)
INNER JOIN BankNumbers AS ToBankNumbers ON (ToBankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND ToBankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
CROSS JOIN Values
WHERE BankWithdrawals.BankWithdrawalStateID = 7 /* CONFIRMED */
 AND BankWithdrawals.SendingBankAccountID = Values.SendingBankAccountID
 AND BankWithdrawals.ToClearingHouseID = Values.ToClearingHouseID
 AND ((FromBankNumbers.BankID = ToBankNumbers.BankID) OR BankWithdrawals.ToClearingHouseID = 7 /* IBAN */) = Values.SameBank
 AND BankWithdrawals.TimestampExecuting > Values.ModificationDate
 AND BankWithdrawals.TimestampExecuting < BankWithdrawals.ModificationDate
 AND BankWithdrawals.ModificationDate < now()-'5 minutes'::interval
LIMIT 1),
     OlderStillExecutedBankWithdrawalID AS (
SELECT BankWithdrawals.BankWithdrawalID FROM BankWithdrawals
INNER JOIN BankAccounts ON (BankAccounts.BankAccountID = BankWithdrawals.SendingBankAccountID)
INNER JOIN BankNumbers AS FromBankNumbers ON (FromBankNumbers.BankNumberID = BankAccounts.BankNumberID)
INNER JOIN BankNumbers AS ToBankNumbers ON (ToBankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND ToBankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
CROSS JOIN Values
WHERE BankWithdrawals.BankWithdrawalStateID = 6 /* EXECUTED */
 AND BankWithdrawals.SendingBankAccountID = Values.SendingBankAccountID
 AND BankWithdrawals.ToClearingHouseID = Values.ToClearingHouseID
 AND ((FromBankNumbers.BankID = ToBankNumbers.BankID) OR BankWithdrawals.ToClearingHouseID = 7 /* IBAN */) = Values.SameBank
 AND BankWithdrawals.TimestampExecuted < Values.TimestampExecuting
 /* We only worry about withdrawals in EXECUTED last 4 days.
 Older withdrawals than that still in EXECUTED must be ignored since we have a lot of old ones due to previous still unsolved problems.
 */
 AND BankWithdrawals.TimestampExecuted > (Values.TimestampExecuting - '4 days'::interval)
 AND BankWithdrawals.TimestampExecuting < BankWithdrawals.TimestampExecuted
LIMIT 1),
     BankLedgerScanID AS (
SELECT BankLedgerScans.BankLedgerScanID
FROM BankLedgerScans
CROSS JOIN Values
WHERE BankLedgerScans.BankAccountID = Values.SendingBankAccountID
 AND BankLedgerScans.ScanInitiated > (Values.ModificationDate + '5 minutes'::interval)
 AND BankLedgerScans.ScanCompleted > BankLedgerScans.ScanInitiated
LIMIT 1),
     Results AS (
SELECT Values.*,
     (SELECT * FROM MoreRecentConfirmedBankWithdrawalID) AS MoreRecentConfirmedBankWithdrawalID,
     (SELECT * FROM OlderStillExecutedBankWithdrawalID) AS OlderStillExecutedBankWithdrawalID,
     (SELECT * FROM BankLedgerScanID) AS BankLedgerScanID
FROM Values)
SELECT *,
     --
     CASE WHEN OlderStillExecutedBankWithdrawalID  IS NOT NULL THEN  FALSE
          WHEN MoreRecentConfirmedBankWithdrawalID IS NULL     THEN  FALSE
          WHEN BankLedgerScanID                    IS NULL     THEN  FALSE
          ELSE                                                       TRUE
          END AS TrustNotExecuted,
     CASE WHEN OlderStillExecutedBankWithdrawalID  IS NOT NULL THEN  format('DEBUG_TRUST_NOT_EXECUTED Cannot tell if BankWithdrawalID %s could have been executed since BankWithdrawalID %s is still EXECUTED before it in time', BankWithdrawalID,OlderStillExecutedBankWithdrawalID)
          WHEN MoreRecentConfirmedBankWithdrawalID IS NULL     THEN  format('DEBUG_TRUST_NOT_EXECUTED Cannot tell if BankWithdrawalID %s could have been executed since there is no CONFIRMED withdrawal after it in time', BankWithdrawalID)
          WHEN BankLedgerScanID                    IS NULL     THEN  format('DEBUG_TRUST_NOT_EXECUTED Cannot tell if BankWithdrawalID %s could have been executed since there is no BankLedgerScan after it in time', BankWithdrawalID)
          ELSE                                                       format('DEBUG_TRUST_NOT_EXECUTED BankWithdrawalID %s is trusted to not be executed since BankWithdrawalID %s was CONFIRMED after it in time and we have successfully scanned the ledger after it in time, BankLedgerScanID %s', BankWithdrawalID, MoreRecentConfirmedBankWithdrawalID, BankLedgerScanID)
          END AS Debug
FROM Results;


\echo "*** IMP: Please run  :check_auto_retry_pending_payments  afterwards to check whether the withdrawal will be retried automatically ***"


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'check_safe_to_retry');
\i '~/.support-sql-procedures/userlogsetup.psql'
