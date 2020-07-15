/* All entrysteps active for a merchant */

\prompt 'Please enter a ProcessingAccount', processingaccount
\prompt 'Please enter a category (deposit / withdraw)', category

\set QUIET ON

\pset expanded off

SELECT
     DistinctEntryStepIdentifiers.Identifier,
     DistinctEntryStepIdentifiers.EntryStepID,
     DistinctEntryStepIdentifiers.Name,
     DistinctEntryStepIdentifiers.Category,
     DistinctEntryStepIdentifiers.SubCategory,
     DistinctEntryStepIdentifiers.BankLogo,
     DistinctEntryStepIdentifiers.CountryCode,
     DistinctEntryStepIdentifiers.CountryName,
     DistinctEntryStepIdentifiers.BankCode,
     CASE WHEN DistinctEntryStepIdentifiers.IsInstant = 1 AND DistinctEntryStepIdentifiers.Category = :'category' AND DistinctEntryStepIdentifiers.Risky IS TRUE THEN 0
          WHEN DistinctEntryStepIdentifiers.IsInstant IS NULL AND DistinctEntryStepIdentifiers.IsInstantFunction IS NOT NULL THEN IsInstant_EntryStep(DistinctEntryStepIdentifiers.EntryStepID, (SELECT UserID FROM Users WHERE Username = :'processingaccount'))
          ELSE DistinctEntryStepIdentifiers.IsInstant
     END AS IsInstant,
     DistinctEntryStepIdentifiers.Priority,
     DistinctEntryStepIdentifiers.allow
 FROM (
     SELECT DISTINCT ON (EntrySteps.Identifier)
         EntrySteps.Identifier,
         EntrySteps.EntryStepID,
         EntrySteps.Name,
         EntrySteps.Category,
         EntrySteps.SubCategory,
         EntrySteps.BankLogo,
         Countries.Code AS CountryCode,
         Countries.Name AS CountryName,
         Banks.Name::text AS BankCode,
         EntrySteps.IsInstant,
         EntrySteps.Risky,
         EntrySteps.IsInstantFunction,
         EntrySteps.Priority,
         EntrySteps.Unlisted,
         coalesce(
             UserEntrySteps.Allow::boolean,
             UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL
         ) AS Allow
     FROM EntrySteps
     LEFT JOIN Countries ON Countries.CountryID = EntrySteps.CountryID
     LEFT JOIN Banks ON Banks.BankID = EntrySteps.BankID
     LEFT JOIN UserEntrySteps ON UserEntrySteps.EntryStepID = EntrySteps.EntryStepID AND UserEntrySteps.UserID IN (SELECT UserID FROM Users WHERE Username = :'processingaccount')
     LEFT JOIN UserEntryStepCountries ON (UserEntryStepCountries.UserID IN (SELECT UserID FROM Users WHERE Username = :'processingaccount') AND UserEntryStepCountries.CountryID = EntrySteps.CountryID AND EntrySteps.Standard IS TRUE AND (UserEntryStepCountries.EnableRisky IS TRUE OR EntrySteps.Risky IS FALSE)
      AND NOT EXISTS (
              SELECT 1
              FROM EntryStepExclusionList
              WHERE
                 EntryStepExclusionList.CountryID = UserEntryStepCountries.CountryID AND
                 EntryStepExclusionList.UserCategoryID IN (SELECT UserCategoryID FROM Users WHERE Username = :'processingaccount') AND
                 EntryStepExclusionList.EntryStepCategory = EntrySteps.Category
          )
        )
     WHERE EntrySteps.Category = :'category'
       AND (EntrySteps.Disabled IS NULL)
     ORDER BY EntrySteps.Identifier, coalesce(UserEntrySteps.Allow::boolean,UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL) DESC,
         CASE WHEN UserEntrySteps.UserEntryStepID IS NOT NULL THEN 1
              WHEN UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL THEN 2
         END
 ) AS DistinctEntryStepIdentifiers
 WHERE DistinctEntryStepIdentifiers.Allow IS TRUE
 ORDER BY DistinctEntryStepIdentifiers.CountryName ASC;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'merchant_entrysteps');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
