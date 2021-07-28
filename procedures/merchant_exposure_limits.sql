/* Exoposure Limits of a Merchant */

\prompt 'Please enter a Processing Account', processingaccount

\set QUIET ON

\pset expanded off

WITH test AS(
            SELECT DistinctEntryStepIdentifiers.UserID,
                   DistinctEntryStepIdentifiers.Username,
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
                                WHEN EntrySteps.IsInstant = 1 AND EntrySteps.Category = 'deposit' AND EntrySteps.Risky IS TRUE THEN 0
                                WHEN EntrySteps.IsInstant IS NULL AND EntrySteps.IsInstantFunction IS NOT NULL THEN IsInstant_EntryStep(EntrySteps.EntryStepID, users.userid)
                                ELSE EntrySteps.IsInstant
                                 END) AS IsInstant,
                          EntrySteps.Priority,
                          COALESCE(UserEntrySteps.Allow::boolean,
                          UserEntryStepCountries.UserEntryStepCountryID IS NOT NULL
                        ) AS Allow,
                        Users.UserID,
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
              WHERE DistinctEntryStepIdentifiers.category = 'deposit' --CHOOSE CATEGORY
                AND DistinctEntryStepIdentifiers.allow = 't'
                --AND DistinctEntryStepIdentifiers.CountryName = 'Estonia'
              ORDER BY DistinctEntryStepIdentifiers.CountryName ASC
            /*SELECT u.userid AS userid, e.entrystepid AS entrystepid, e.username AS username, e.name AS bankname, e.countryname AS countryname
              FROM view_user_entrysteps e
              JOIN users u ON u.username=e.username
             WHERE e.allow = 'YES'
               AND e.username = :'processingaccount'
               AND e.category='deposit'
             --AND e.entrystepid=492
             --AND countryname = 'Germany'*/
            )
      SELECT test.username,test.entrystepid,test.name,test.countryname,
             (Get_Exposure_Limit(3,test.userid,test.EntryStepID, NULL, NULL, NULL, 'CONFIRMED_PER_PERSON')).limitcurrency,
             (Get_Exposure_Limit(3,test.userid,test.EntryStepID, NULL, NULL, NULL, 'CONFIRMED_PER_PERSON')).exposurelimit AS CONFIRMED_PER_PERSON,
             (Get_Exposure_Limit(3,test.userid,test.EntryStepID, NULL, NULL, NULL, 'UNCONFIRMED_PER_PERSON')).exposurelimit AS UNCONFIRMED_PER_PERSON
        FROM test;

\echo 'Please note there might be EndUser Specific Limits!'
