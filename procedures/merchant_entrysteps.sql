/* All entrysteps active for a merchant */

\prompt 'Please enter a ProcessingAccount', processingaccount
\prompt 'Please enter a category (deposit / withdraw)', category

\set QUIET ON

\pset expanded off

SELECT DistinctEntryStepIdentifiers.Username,
       DistinctEntryStepIdentifiers.Identifier,
       DistinctEntryStepIdentifiers.EntryStepID,
       DistinctEntryStepIdentifiers.Name,
       DistinctEntryStepIdentifiers.Category,
       DistinctEntryStepIdentifiers.SubCategory,
       DistinctEntryStepIdentifiers.CountryCode,
       DistinctEntryStepIdentifiers.CountryName,
       DistinctEntryStepIdentifiers.BankCode,
       DistinctEntryStepIdentifiers.IsInstant,
       DistinctEntryStepIdentifiers.Priority,
       DistinctEntryStepIdentifiers.allow
  FROM (
       SELECT DISTINCT ON (EntrySteps.Identifier)
              EntrySteps.Identifier,
              EntrySteps.EntryStepID,
              EntrySteps.Name,
              EntrySteps.Category,
              EntrySteps.SubCategory,
              Countries.Code AS CountryCode,
              Countries.Name AS CountryName,
              Banks.Name::text AS BankCode,
              (CASE WHEN Users.PromptDepositLimitMessage IS FALSE THEN NULL::integer
                    WHEN EntrySteps.IsInstant = 1 AND EntrySteps.Category = :'category' AND EntrySteps.Risky IS TRUE THEN 0
                    WHEN EntrySteps.IsInstant IS NULL AND EntrySteps.IsInstantFunction IS NOT NULL THEN IsInstant_EntryStep(EntrySteps.EntryStepID, users.userid)
                    ELSE EntrySteps.IsInstant
                     END) AS IsInstant,
              EntrySteps.Priority,
              (CASE WHEN UserSettings.RequireFetchAccountFromBank IS TRUE AND Entrysteps.Name IN ('Other bank', 'IBAN/SEPA') THEN 'f'
                    WHEN UserSettings.RequireFetchAccountFromBank IS TRUE AND NOT EXISTS (SELECT 1 FROM Get_Account_Selector(Entrysteps.EntrystepID, Users.UserID)) THEN 'f' ELSE COALESCE(UserEntrySteps.Allow::boolean, UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL)
                     END) AS Allow,
              Users.Username
         FROM Users
         JOIN UserSettings ON UserSettings.UserID = Users.UserID
        CROSS JOIN EntrySteps
         LEFT JOIN Countries ON (Countries.CountryID = EntrySteps.CountryID)
         LEFT JOIN Banks ON (Banks.BankID = EntrySteps.BankID)
         LEFT JOIN UserEntrySteps ON (UserEntrySteps.EntryStepID = EntrySteps.EntryStepID AND UserEntrySteps.UserID = Users.UserID)
         LEFT JOIN UserEntryStepCountries ON (UserEntryStepCountries.UserID = Users.UserID AND UserEntryStepCountries.CountryID = EntrySteps.CountryID AND EntrySteps.Standard IS TRUE AND (UserEntryStepCountries.EnableRisky IS TRUE OR EntrySteps.Risky IS FALSE)
          AND NOT EXISTS (
            SELECT 1
              FROM EntryStepExclusionList
             WHERE EntryStepExclusionList.CountryID = UserEntryStepCountries.CountryID
               AND EntryStepExclusionList.UserCategoryID = Users.UserCategoryID
               AND EntryStepExclusionList.EntryStepCategory = EntrySteps.Category
             )
           )
        WHERE Users.Username = :'processingaccount'
          AND (EntrySteps.Disabled IS NULL OR users.username = 'apitest')
          AND (EntrySteps.Unlisted IS FALSE OR users.username = 'apitest')
        ORDER BY EntrySteps.Identifier, COALESCE(UserEntrySteps.Allow::boolean, UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL) DESC,
              (CASE WHEN UserEntrySteps.UserEntryStepID IS NOT NULL THEN 1
                    WHEN UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL THEN 2
                     END)
        ) AS DistinctEntryStepIdentifiers
  WHERE DistinctEntryStepIdentifiers.category = :'category'
    AND DistinctEntryStepIdentifiers.allow = 't'
  ORDER BY DistinctEntryStepIdentifiers.CountryName ASC
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'merchant_entrysteps.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
