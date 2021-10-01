/* Provides All information needed for GDPR requirements
   Gets PersonID of an end user
   Note to author: Query needs updating when new KYC model is launched with KYC schema */

\prompt 'Please enter an OrderID', orderID

\set QUIET ON

\pset expanded on


WITH Parameters AS(
  SELECT unnest(pg_temp.Get_relalted_GDPR_TransferBankAccounts(:'orderID')) AS TransferBankAccountIDs
  ),
  OrdersCollection AS (
    SELECT DISTINCT BankOrders.OrderID AS OrderIDs, TransferBankAccountID AS TransferBankAccountIDs
      FROM BankOrders
     WHERE BankOrders.TransferBankAccountID IN (SELECT TransferBankAccountIDs FROM Parameters)
       AND BankOrders.Datestamp >= now() -'10 years'::interval
     UNION
    SELECT DISTINCT orderbankaccounts.OrderID AS OrderIDs, TransferBankAccountID AS TransferBankAccountIDs
      FROM orderbankaccounts
     WHERE orderbankaccounts.TransferBankAccountID IN (SELECT TransferBankAccountIDs FROM Parameters)
       AND orderbankaccounts.Datestamp >= now() -'10 years'::interval
     UNION
    SELECT DISTINCT accountselectortransfers.OrderID AS OrderIDs, TransferBankAccountID AS TransferBankAccountIDs
      FROM accountselectortransfers
     WHERE accountselectortransfers.TransferBankAccountID IN (SELECT TransferBankAccountIDs FROM Parameters)
       AND accountselectortransfers.Datestamp >= now() -'10 years'::interval
     UNION
    SELECT DISTINCT Transfers.OrderID AS OrderIDs, TransferBankAccountID AS TransferBankAccountIDs
      FROM Transfers
      JOIN autogiro.payments ON Transfers.TransferID = Payments.TransferID AND Transfers.TransferTypeID = 1
      JOIN autogiro.payers ON Payers.PayerID = Payments.PayerID
      JOIN TransferBankAccounts ON TransferBankAccounts.AccountID = Payers.AccountID
     WHERE payers.AccountID IN (SELECT AccountID FROM TransferBankAccounts WHERE TransferbankaccountID IN (SELECT TransferBankAccountIDs FROM Parameters))
       AND payments.Datestamp >= now() -'10 years'::interval
     UNION
    SELECT :'orderID' AS OrderIDs, NULL AS TransferBankAccountIDs
     ),
     CollectedData AS(
       SELECT DISTINCT
              array[lower(TransferBankAccounts.Name)] || array[lower(Public.Entities.Name)] || array[lower(concat(OrderAttributes.FirstName,' ',OrderAttributes.LastName))] || array[lower(TransferBankAccounts.KYCData::json->>'name')] || array[lower(OrdersKycData.Name)] || array[lower(concat(KYC.PnpOrders.kycdata::json->>'firstName', ' ',KYC.PnpOrders.kycdata::json->>'lastName'))] || array[lower(KYC.Entities.Name)] || array[lower(KYC.Endusers.Name)] AS Names,
              array[Orderskycdata.dob] || array[Kyc.Entities.dob] || array[TransferBankAccounts.Dob] || array[OrderAttributes.Dob] || array[KYC.PnpOrders.Dob] AS DateofBirth,
              array[OrdersKycData.Gender] || array[kyc.entities.gender] || array[TransferBAnkAccounts.Gender] AS Gender,
              array[lower(OrdersKycData.Address)]  || array[lower(KYC.Entities.FullAddress::json->>'address')] || array[lower(Public.Entities.Address)] || array[lower(TransferBankAccounts.Address)] || array[lower(KYC.PnpOrders.kycdata::json->>'street'::text)] AS Addresses,
              array[OrdersKycData.Zipcode] || array[Public.Entities.Zipcode] || array[TransferBankAccounts.Zipcode] || array[KYC.PnpOrders.kycdata::json->>'Zipcode'::text] AS Zipcodes,
              array[lower(OrdersKycData.City)] || array[lower(Public.Entities.City)] || array[lower(TransferBankAccounts.City)] || array[lower(KYC.PNPorders.kycdata::json->>'city')] AS Cities,
              array[upper(OrdersKycData.Country)] || array[upper(Public.Entities.Country)] || array[upper(TransferBankAccounts.Country)] || array[upper(Countries.Name)] AS Countries,
              array[Public.Entities.PersonID] ||  array[TransferBankAccounts.PersonID] ||  array[array_to_string(TransferBankAccounts.PersonIDs,',')] ||  array[KYC.Entities.PersonID] || array[OrdersKycData.personID] || array[KYC.PnpOrders.PersonID] || array[OrderAttributes.NationalIdentificationNumber] AS PersonIDs,
              array[TransferBankAccounts.AccountNumber] || array[KYC.PnpOrders.kycdata::json->'accounts'->(0)->>'fullaccountnumber'::text] ||  array[KYC.PnpOrders.kycdata::json->'accounts'->(1)->>'fullaccountnumber'::text] || array[KYC.PnpOrders.kycdata::json->'accounts'->(2)->>'fullaccountnumber'::text] || array[KYC.PnpOrders.kycdata::json->'accounts'->(3)->>'fullaccountnumber'::text] || array[KYC.PnpOrders.kycdata::json->'accounts'->(4)->>'fullaccountnumber'::text] AS BankAccounts,
              array[TransferBankAccounts.bankNumber] AS BankNumber,
              array[replace(replace(replace(KYC.Entities.PhoneNumber, '+', ''), ' ', ''), '-','')] || array[replace(replace(replace(OrderAttributes.MobilePhone, '+',''), ' ', ''), '-','')] AS PhoneNumbers,
              array[lower(Public.Entities.Email)] || array[lower(KYC.Entities.Email)] || array[lower(OrderAttributes.Email)] || array[lower(KYC.Endusers.Email)] AS EmailAddresses,
              array[Sessions.EnduserHost] AS IPAddresses,
              array[concat(EnduserClientPlatforms.os, ' ', EnduserClientPlatforms.osversion)] AS OperatingSystems,
              array[concat(EnduserClientPlatforms.browser, ' ', EnduserClientPlatforms.browserversion)] AS Browsers,
              array[EnduserClientPlatforms.hardware::text] AS Hardware,
              Countries.Code AS countrycode
         FROM OrdersCollection
         JOIN Orders ON OrdersCollection.OrderIDs = Orders.OrderID
         LEFT JOIN Public.Entities ON Entities.EntityID = Orders.EntityID
         LEFT JOIN OrderAttributes ON (OrderAttributes.OrderID = OrdersCollection.orderids) AND (Orderattributes.FirstName IS NOT NULL) AND (OrderAttributes.LastName IS NOT NULL)
         LEFT JOIN TransferBankAccounts ON TransferBankAccounts.TransferBankAccountID = OrdersCollection.TransferBankAccountIDs
         LEFT JOIN Countries ON (Countries.code = OrderAttributes.Country)
         LEFT JOIN OrdersKycData ON (OrdersKycData.OrderID = OrdersCollection.orderids)
         LEFT JOIN KYC.PnpOrders ON (KYC.PnpOrders.OrderID = OrdersCollection.orderids)
         LEFT JOIN KYC.OrdersEntity ON KYC.OrdersEntity.OrderID = OrdersCollection.orderids
         LEFT JOIN KYC.Entities ON (KYC.Entities.kycentityid = KYC.ordersentity.kycentityid)
         LEFT JOIN kyc.endusers ON  kyc.endusers.kycenduserID = KYC.OrdersEntity.kycenduserID
         LEFT JOIN Sessions ON Sessions.SessionID = (SELECT SessionID FROM Orders WHERE OrderID = OrdersCollection.orderids)
         LEFT JOIN OrderFingerPrints ON OrderFingerPrints.OrderID = OrdersCollection.orderids
         LEFT JOIN FingerPrints ON FingerPrints.FingerprintID = OrderFingerPrints.fingerprintid
         LEFT JOIN EnduserClientPlatforms ON enduserclientplatforms.enduserclientplatformid = FingerPrints.enduserclientplatformid
        WHERE Orders.OrderID = OrdersCollection.OrderIDs
      ),
      ArrayElements AS(
        SELECT unnest(CollectedData.names) AS Names,
               unnest(CollectedData.DateOfBirth) AS DateOfBirth,
               unnest(CollectedData.Gender) AS Gender,
               unnest(CollectedData.Addresses) AS Addresses,
               unnest(CollectedData.ZipCodes) AS ZipCodes,
               unnest(CollectedData.Cities) AS Cities,
               unnest(CollectedData.Countries) AS Countries,
               unnest(CollectedData.PersonIDs) AS personID,
               unnest(CollectedData.BankAccounts) AS BankAccounts,
               unnest(CollectedData.BankNumber) AS BankNumber,
               unnest(CollectedData.PhoneNumbers) AS PhoneNumbers,
               unnest(CollectedData.EmailAddresses) AS EmailAddresses,
               unnest(CollectedData.OperatingSystems) AS OperatingSystems,
               unnest(CollectedData.Browsers) AS Browsers,
               unnest(CollectedData.Hardware) AS Hardware,
               unnest(CollectedData.IPAddresses) AS IPAddresses,
               Collecteddata.countrycode
          FROM CollectedData
          )
          SELECT regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.names) FILTER(WHERE ArrayElements.names IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Name,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.DateOfBirth) FILTER(WHERE ArrayElements.DateOfBirth IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS DateOfBirth,
                 --regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Gender) FILTER(WHERE ArrayElements.Gender IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Gender,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Addresses) FILTER(WHERE ArrayElements.Addresses IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Address,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.ZipCodes) FILTER(WHERE ArrayElements.ZipCodes IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS ZipCode,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Cities) FILTER(WHERE ArrayElements.Cities IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS City,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Countries) FILTER(WHERE ArrayElements.Countries IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Country,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.PersonID) FILTER(WHERE ArrayElements.PersonID IS NOT NULL AND (personid_validator(ArrayElements.PersonID, ArrayElements.countrycode)).validatedpersonid IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS personID,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.BankAccounts) FILTER(WHERE ArrayElements.BankAccounts IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS BankAccounts,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.BankNumber) FILTER(WHERE ArrayElements.BankNumber IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS BankNumber,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.PhoneNumbers) FILTER(WHERE ArrayElements.PhoneNumbers IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS PhoneNumbers,
                 regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.EmailAddresses) FILTER(WHERE ArrayElements.EmailAddresses IS NOT NULL AND substring(ArrayElements.EmailAddresses,'@(.*)') NOT IN ('example.com','trustlyclient.com'))::text,'" ",',''),'{',''),'}',''),'"",','') AS EmailAddresses
                 --regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.OperatingSystems) FILTER(WHERE ArrayElements.OperatingSystems IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS OperatingSystems,
                 --regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Browsers) FILTER(WHERE ArrayElements.Browsers IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Browsers,
                 --regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.Hardware) FILTER(WHERE ArrayElements.Hardware IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS Hardware,
                 --regexp_replace(regexp_replace(regexp_replace(regexp_replace(array_agg(DISTINCT ArrayElements.IPAddresses) FILTER(WHERE ArrayElements.IPAddresses IS NOT NULL)::text,'" ",',''),'{',''),'}',''),'"",','') AS IPAddresses
            FROM ArrayElements;
