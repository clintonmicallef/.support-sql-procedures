/* All entrysteps active for a merchant */

\prompt 'Please enter a ProcessingAccount', processingaccount
\prompt 'Please enter a category (deposit / withdraw)', category

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
              COALESCE(UserEntrySteps.Allow::boolean,
              UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL
            ) AS Allow,
            Users.Username
         FROM Users
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
                              ))
        WHERE Users.Username = :'processingaccount' --CHANGE USERNAME
          AND (EntrySteps.Disabled IS NULL OR users.username = 'apitest')
          AND (EntrySteps.Unlisted IS FALSE OR users.username = 'apitest')
        ORDER BY EntrySteps.Identifier, COALESCE(UserEntrySteps.Allow::boolean, UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL) DESC,
              (CASE WHEN UserEntrySteps.UserEntryStepID IS NOT NULL THEN 1
                    WHEN UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL THEN 2
                     END)
        ) AS DistinctEntryStepIdentifiers
  WHERE DistinctEntryStepIdentifiers.category = :'category' --CHOOSE CATEGORY
    AND DistinctEntryStepIdentifiers.allow = 't'
    --AND DistinctEntryStepIdentifiers.CountryName = 'Belgium'
  ORDER BY DistinctEntryStepIdentifiers.CountryName ASC;
