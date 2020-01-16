/* All routing options for entire Withdrawals Queue */

\prompt 'Please enter an EcoSysAccount', ecosysaccount

\set QUIET ON

\pset expanded off

WITH Queued_Withdrawals AS (
    SELECT View_Bank_Withdrawals_In_Queue.EcoSysAccount,
           View_Bank_Withdrawals_In_Queue.BankWithdrawalID,
           View_Bank_Withdrawals_In_Queue.Prio,
           View_Bank_Withdrawals_In_Queue.Bank,
           Users.Username,
           UserCategories.Name AS UserCategory,
           BankWithdrawalTypes.BankWithdrawalType,
           BankWithdrawals.Amount,
           BankWithdrawals.Currency,
           BankWithdrawals.Attempts,
           BankWithdrawals.Dequeued,
           BankWithdrawals.RetryNow,
           BankWithdrawals.Datestamp::timestamp(0),
           (now() - BankWithdrawals.Datestamp)::interval(0) AS Delay
      FROM View_Bank_Withdrawals_In_Queue
      JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID = View_Bank_Withdrawals_In_Queue.BankWithdrawalID)
      JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
      JOIN Users ON (Users.UserID = BankWithdrawals.UserID)
      JOIN UserCategories ON (UserCategories.UserCategoryID = Users.UserCategoryID)
     WHERE View_Bank_Withdrawals_In_Queue.EcoSysAccount = :'ecosysaccount'
     ORDER BY View_Bank_Withdrawals_In_Queue.EcoSysAccount, View_Bank_Withdrawals_In_Queue.Prio
   ), Queued_Withdrawals_SBA_Candidates AS (
     SELECT ROW_NUMBER() OVER (
            PARTITION BY Candidates.BankWithdrawalID
                ORDER BY -- This should be identical with View_Sending_Bank_Account_Candidates()
            Candidates.banknumberpreferredroute DESC,
            Candidates.SendingBankAccount DESC NULLS LAST,
            Candidates.ClearingHouseBankAccount DESC NULLS LAST,
            Candidates.BankGroup DESC NULLS LAST,
            Candidates.IntraBank DESC NULLS LAST,
            Candidates.Priority ASC NULLS LAST,
            Candidates.Balance DESC NULLS LAST),
            Candidates.*
       FROM (
         SELECT (Get_Sending_Bank_Account_Candidates(_UserID := BankWithdrawals.UserID,
                                                   _Currency := BankWithdrawals.Currency,
                                                     _Amount := BankWithdrawals.Amount,
                                         _BankWithdrawalType := BankWithdrawalTypes.BankWithdrawalType,
                                               _ToBankNumber := BankNumbers.banknumber,
                                          _ToClearingHouseID := BankWithdrawals.ToClearingHouseID,
                                         _SendingBankAccount := NULL)).*,
                BankWithdrawals.TransferBankAccountID,
                Queued_Withdrawals.BankWithdrawalID
           FROM Queued_Withdrawals
           JOIN BankWithdrawals ON (BankWithdrawals.BankWithdrawalID = Queued_Withdrawals.BankWithdrawalID)
           JOIN BankWithdrawalTypes ON (BankWithdrawalTypes.BankWithdrawalTypeID = BankWithdrawals.BankWithdrawalTypeID)
           JOIN BankNumbers ON (BankNumbers.BankNumber = BankWithdrawals.ToBankNumber AND BankNumbers.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
           JOIN Banks ON (Banks.BankID = BankNumbers.BankID)
           JOIN ClearingHouses ON (ClearingHouses.ClearingHouseID = BankWithdrawals.ToClearingHouseID)
         ) AS Candidates
     WHERE Candidates.WithdrawalsEnabled
       AND Candidates.AllowWithdrawals
       AND Candidates.BankAccountCutOffTimes
       AND Candidates.BalanceNotExceeded
       AND Candidates.MaxAmount
       AND Candidates.Whitelist
       AND Candidates.NotAvoidRoute
       AND NOT EXISTS (
         SELECT 1
           FROM AvoidWithdrawalRoutesToSpecificAccounts
          WHERE AvoidWithdrawalRoutesToSpecificAccounts.TransferBankAccountID  = Candidates.TransferBankAccountID
            AND AvoidWithdrawalRoutesToSpecificAccounts.SendingBankAccountID     = Candidates.BankAccountID
          )
       AND NOT EXISTS (
         SELECT 1
           FROM ReroutedBankWithdrawals
          WHERE ReroutedBankWithdrawals.TransferBankAccountID  = Candidates.TransferBankAccountID
            AND ReroutedBankWithdrawals.OldSendingBankAccountID  = Candidates.BankAccountID
            --AND ReroutedBankWithdrawals.Permanent                = TRUE
          )
        )
        SELECT Queued_Withdrawals.*,
               (SELECT (array_agg(Queued_Withdrawals_SBA_Candidates.EcoSysAccount))[1:5]
                  FROM Queued_Withdrawals_SBA_Candidates
                 WHERE Queued_Withdrawals_SBA_Candidates.BankWithdrawalID = Queued_Withdrawals.BankWithdrawalID) AS SBA_Candidates
          FROM Queued_Withdrawals
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'queue_routing_candidates.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
