/* Find alternative payout routes for a BankWithdrawalID */

\prompt 'Please enter a BankWithdrawalID', bankwithdrawalID

\set QUIET ON

\pset expanded on

SELECT Candidates.*
  FROM (
        SELECT (Get_Sending_Bank_Account_Candidates(_UserID := BankWithdrawals.UserID,
                                                  _Currency := BankWithdrawals.Currency,
                                                    _Amount := BankWithdrawals.Amount,
                                        _BankWithdrawalType := BankWithdrawalTypes.BankWithdrawalType,
                                              _ToBankNumber := BankNumbers.BankNumber,
                                         _ToClearingHouseID := BankWithdrawals.ToClearingHouseID,
                                        _SendingBankAccount := NULL)).*
          FROM BankWithdrawals
          JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
          JOIN BankNumbers ON (BankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND BankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
          JOIN Banks ON (Banks.BankID = BankNumbers.BankID)
          JOIN ClearingHouses ON (ClearingHouses.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
         WHERE BankWithdrawalID = :'bankwithdrawalID'
       ) AS Candidates
 WHERE Candidates.WithdrawalsEnabled AND
       Candidates.AllowWithdrawals AND
       Candidates.BankAccountCutOffTimes AND
       Candidates.BalanceNotExceeded AND
       Candidates.MaxAmount AND
       Candidates.Whitelist AND
       Candidates.NotAvoidRoute
 ORDER BY Candidates.banknumberpreferredroute DESC,
          Candidates.SendingBankAccount DESC NULLS LAST,
          Candidates.ClearingHouseBankAccount DESC NULLS LAST,
          Candidates.BankGroup DESC NULLS LAST,
          Candidates.IntraBank DESC NULLS LAST,
          Candidates.Priority ASC NULLS LAST,
          Candidates.Balance DESC NULLS LAST
LIMIT 5;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'get_withdrawal_routes.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
