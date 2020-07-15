/* PROCEDURE:Risk (exposure) limits of a processing account */

\prompt 'Please enter a ProcessingAccount', processingaccount

\set QUIET ON

\pset expanded off

WITH SelectedEntrySteps AS (
    SELECT UserEntrySteps.EntryStepID, (SELECT userID FROM Users WHERE Username = :'processingaccount') AS UserID
         FROM Get_User_Entry_Steps(:'processingaccount', 'deposit', True) UserEntrySteps
     )
     , EntryStepExposureLimits AS (
         SELECT
             ExposureLimit.EntryStepID,
             (ExposureLimit).ExposureLimitID,
             (ExposureLimit).ExposureLimit,
             (ExposureLimit).LimitCurrency,
             (UnconfirmedExposureLimit).ExposureLimitID AS UnconfirmedExposureLimitID,
             (UnconfirmedExposureLimit).ExposureLimit AS UnconfirmedExposureLimit,
             (UnconfirmedExposureLimit).LimitCurrency AS UnconfirmedLimitCurrency
         FROM
         (
             SELECT
                 EntrySteps.EntryStepID,
                 Get_Exposure_Limit(3, SelectedEntrySteps.UserID, EntrySteps.EntryStepID, NULL::text, NULL::text, NULL::uuid, 'CONFIRMED_PER_PERSON') AS ExposureLimit,
                 Get_Exposure_Limit(3, SelectedEntrySteps.UserID, EntrySteps.EntryStepID, NULL::text, NULL::text, NULL::uuid, 'UNCONFIRMED_PER_PERSON') AS UnconfirmedExposureLimit
             FROM SelectedEntrySteps
             JOIN EntrySteps ON (EntrySteps.EntryStepID = SelectedEntrySteps.EntryStepID)
             JOIN Banks ON (Banks.BankID = EntrySteps.BankID)
         ) ExposureLimit
         WHERE (ExposureLimit).ExposureLimitID IS NOT NULL
     )
     SELECT
         ClearingHouses.Name::text AS ClearingHouse,
         X.EntryStepID,
         Banks.Name::text AS BankNameShort,
         Banks.LongName::text AS BankNameLong,
         CASE WHEN EntrySteps.Risky THEN 'Yes' ELSE 'No' END AS Risky,
         X.LimitCurrency || ' ' || X.ExposureLimit AS RiskLimit,
         CASE
             WHEN ExposureLimits.UserID IS NOT NULL AND
                  ExposureLimits.EntryStepID IS NOT NULL THEN        'Merchant/Entry Step'
             WHEN ExposureLimits.UserID IS NOT NULL AND
                  ExposureLimits.ClearingHouseID IS NOT NULL THEN    'Merchant/Clearing House'
             WHEN ExposureLimits.UserID IS NOT NULL THEN             'Merchant'
             WHEN ExposureLimits.EntryStepID IS NOT NULL THEN        'Entry Step'
             WHEN ExposureLimits.ClearingHouseID IS NOT NULL THEN    'Clearing House'
             ELSE 'Global' END AS LimitLevel,
         X.UnconfirmedLimitCurrency || ' ' || X.UnconfirmedExposureLimit AS RiskLimitUnconfirmed,
         CASE
             WHEN UnconfirmedExposureLimits.UserID IS NOT NULL AND
                  UnconfirmedExposureLimits.EntryStepID IS NOT NULL THEN        'Merchant/Entry Step'
             WHEN UnconfirmedExposureLimits.UserID IS NOT NULL AND
                  UnconfirmedExposureLimits.ClearingHouseID IS NOT NULL THEN    'Merchant/Clearing House'
             WHEN UnconfirmedExposureLimits.UserID IS NOT NULL THEN             'Merchant'
             WHEN UnconfirmedExposureLimits.EntryStepID IS NOT NULL THEN        'Entry Step'
             WHEN UnconfirmedExposureLimits.ClearingHouseID IS NOT NULL THEN    'Clearing House'
             ELSE 'Global' END AS LimitLevelUnconfirmed
     FROM
     (
         SELECT
             SelectedEntrySteps.EntryStepID,
             EntryStepExposureLimits.ExposureLimitID AS ExposureLimitID,
             EntryStepExposureLimits.LimitCurrency AS LimitCurrency,
             EntryStepExposureLimits.ExposureLimit AS ExposureLimit,
             EntryStepExposureLimits.UnconfirmedExposureLimitID AS UnconfirmedExposureLimitID,
             EntryStepExposureLimits.UnconfirmedLimitCurrency AS UnconfirmedLimitCurrency,
             EntryStepExposureLimits.UnconfirmedExposureLimit AS UnconfirmedExposureLimit
         FROM SelectedEntrySteps
         LEFT JOIN EntryStepExposureLimits
             ON (EntryStepExposureLimits.EntryStepID = SelectedEntrySteps.EntryStepID)
     ) X
     JOIN ExposureLimits
         ON (ExposureLimits.ExposureLimitID = X.ExposureLimitID)
     JOIN ExposureLimits AS UnconfirmedExposureLimits
         ON (UnconfirmedExposureLimits.ExposureLimitID = X.UnconfirmedExposureLimitID)
     JOIN EntrySteps
         ON (EntrySteps.EntryStepID = X.EntryStepID)
     JOIN Banks
         ON (Banks.BankID = EntrySteps.BankID)
     LEFT JOIN ClearingHouses
         ON (EntrySteps.ClearingHouseID = ClearingHouses.ClearingHouseID)
     ORDER BY ClearingHouses.Name, Banks.LongName, X.EntryStepID
;

-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'merchant_risk_limits');
\i '~/.support-sql-procedures/userlogsetup.psql'
