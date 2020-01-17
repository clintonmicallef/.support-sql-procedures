/* Provides All information needed for GDPR requirements
   Gets PersonID of an end user
   Not to author: Query needs updating when new KYC model is launched with KYC schema */

\prompt 'Please enter an OrderID', orderID

\set QUIET ON

\pset expanded on

WITH CollectedData AS(
  SELECT DISTINCT
         unnest(array[lower(TransferBankAccounts.Name), lower(Public.Entities.Name), lower(concat(OrderAttributes.FirstName,' ',OrderAttributes.LastName)), lower(TransferBankAccounts.KYCData::json->>'name'), lower(OrdersKycData.Name), lower(concat(KYC.PnpOrders.kycdata::json->>'firstName', ' ',KYC.PnpOrders.kycdata::json->>'lastName')), lower(KYC.Entities.Name), lower(KYC.Endusers.Name)]) AS Names,
         unnest(array[(OrdersKycData.Dob), (KYC.Entities.dob), (TransferBankAccounts.Dob), (OrderAttributes.Dob), (KYC.PnpOrders.Dob)]) AS DatesofBirth,
         unnest(array[(OrdersKycData.Gender), (KYC.Entities.Gender), (TransferBankAccounts.Gender)]) AS Genders,
         unnest(array[lower(OrdersKycData.Address), lower(KYC.Entities.FullAddress::json->>'address'), lower(Public.Entities.Address), lower(TransferBankAccounts.Address), lower(KYC.PnpOrders.kycdata::json->>'street'::text)]) AS Addresses,
         unnest(array[(OrdersKycData.Zipcode), (Public.Entities.Zipcode), (TransferBankAccounts.Zipcode), (KYC.PnpOrders.kycdata::json->>'Zipcode'::text)]) AS Zipcodes,
         unnest(array[lower(OrdersKycData.City), lower(Public.Entities.City), lower(TransferBankAccounts.City), lower(KYC.PNPorders.kycdata::json->>'city')]) AS Cities,
         unnest(array[upper(OrdersKycData.Country), upper(Public.Entities.Country), upper(TransferBankAccounts.Country), upper(Countries.Name)]) AS Countries,
         unnest(array[(Public.Entities.PersonID), (TransferBankAccounts.PersonID), (array_to_string(TransferBankAccounts.PersonIDs,',')), (KYC.Entities.PersonID), (OrdersKycData.personID), (KYC.PnpOrders.PersonID), (OrderAttributes.NationalIdentificationNumber)]) AS PersonIDs,
         unnest(array[(TransferBankAccounts.AccountNumber), (KYC.PnpOrders.kycdata::json->'accounts'->(0)->>'fullaccountnumber'::text), (KYC.PnpOrders.kycdata::json->'accounts'->(1)->>'fullaccountnumber'::text), (KYC.PnpOrders.kycdata::json->'accounts'->(2)->>'fullaccountnumber'::text), (KYC.PnpOrders.kycdata::json->'accounts'->(3)->>'fullaccountnumber'::text), (KYC.PnpOrders.kycdata::json->'accounts'->(4)->>'fullaccountnumber'::text)]) AS BankAccounts,
         unnest(array[(replace(replace(replace(KYC.Entities.PhoneNumber, '+', ''), ' ', ''), '-','')), (replace(replace(replace(OrderAttributes.MobilePhone, '+',''), ' ', ''), '-',''))]) AS PhoneNumbers,
         unnest(array[lower(Public.Entities.Email), lower(KYC.Entities.Email), lower(OrderAttributes.Email), lower(KYC.Endusers.Email)]) AS EmailAddresses,
         unnest(array[(Sessions.EnduserHost)]) AS IPAddresses,
         unnest(array[concat(EnduserClientPlatforms.os, ' ', EnduserClientPlatforms.osversion)]) AS OperatingSystems,
         unnest(array[concat(EnduserClientPlatforms.browser, ' ', EnduserClientPlatforms.browserversion)]) AS Browsers,
         unnest(array[EnduserClientPlatforms.hardware]) AS Hardware,
         unnest(array[BlockedPersons.Reason]) AS BlockedReasons
    FROM Orders
    JOIN (
      SELECT OrderIDs, TransferBankAccountIDs
        FROM pg_temp.get_related_orderids(:'orderID')
      ) OrdersCollection ON OrdersCollection.OrderIDs = Orders.orderID
    LEFT JOIN Public.Entities ON Entities.EntityID = Orders.EntityID
    LEFT JOIN OrderAttributes ON (OrderAttributes.OrderID = OrdersCollection.orderids) AND (Orderattributes.FirstName IS NOT NULL) AND (OrderAttributes.LastName IS NOT NULL)
    LEFT JOIN TransferBankAccounts ON TransferBankAccounts.TransferBankAccountID = OrdersCollection.TransferBankAccountIDs
    LEFT JOIN Countries ON (Countries.code = OrderAttributes.Country)
    LEFT JOIN OrdersKycData ON (OrdersKycData.OrderID = OrdersCollection.orderids)
    LEFT JOIN KYC.PnpOrders ON (KYC.PnpOrders.OrderID = OrdersCollection.orderids)
    LEFT JOIN KYC.OrdersEntity ON KYC.OrdersEntity.OrderID = OrdersCollection.orderids
    LEFT JOIN KYC.Entities ON (KYC.Entities.kycentityid = KYC.ordersentity.kycentityid)
    --LEFT JOIN kyc.bankentities
    --LEFT JOIN kyc.bankentitiesaccounts
    LEFT JOIN kyc.endusers ON  kyc.endusers.kycenduserID = KYC.OrdersEntity.kycenduserID
    --LEFT JOIN kyc.endusersentities
    LEFT JOIN Sessions ON Sessions.SessionID = (SELECT SessionID FROM Orders WHERE OrderID = OrdersCollection.orderids)
    LEFT JOIN OrderFingerPrints ON OrderFingerPrints.OrderID = OrdersCollection.orderids
    LEFT JOIN FingerPrints ON FingerPrints.FingerprintID = OrderFingerPrints.fingerprintid
    LEFT JOIN EnduserClientPlatforms ON enduserclientplatforms.enduserclientplatformid = FingerPrints.enduserclientplatformid
    LEFT JOIN BlockedPersons ON BlockedPersons.Personid = ANY(TransferBankAccounts.PersonIDs)
    WHERE Orders.OrderID = OrdersCollection.OrderIds
  )
  SELECT DISTINCT
         array_to_string(array_agg(DISTINCT names),',') AS Names,
         array_to_string(array_agg(DISTINCT DatesofBirth),',') AS DateOfBirths,
         array_to_string(array_agg(DISTINCT genders),',') AS Genders,
         array_to_string(array_agg(DISTINCT addresses),',') AS Addresses,
         array_to_string(array_agg(DISTINCT zipcodes),',') AS ZipCodes,
         array_to_string(array_agg(DISTINCT cities),',') AS Cities,
         array_to_string(array_agg(DISTINCT countries),',') AS Countries,
         array_to_string(array_agg(DISTINCT PersonIDs),',') AS PersonIDs,
         array_to_string(array_agg(DISTINCT BankAccounts),',') AS BankAccounts,
         array_to_string(array_agg(DISTINCT PhoneNumbers),',') AS PhoneNumbers,
         array_to_string(array_agg(DISTINCT EmailAddresses),',') AS EmailAddresses,
         array_to_string(array_agg(DISTINCT IPAddresses),',') AS IPAddresses,
         array_to_string(array_agg(DISTINCT OperatingSystems),',') AS OperatingSystems,
         array_to_string(array_agg(DISTINCT Browsers),',') AS Browsers,
         array_to_string(array_agg(DISTINCT Hardware),',') AS HardWare,
         array_to_string(array_agg(DISTINCT BlockedReasons),',') AS BlockedReasons
    FROM CollectedData
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'gdpr_request.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
