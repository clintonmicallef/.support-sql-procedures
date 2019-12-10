/* Provides All information needed for GDPR requirements
   Gets PersonID of an end user
   Not to author: Query needs updating when new KYC model is launched with KYC schema */

\prompt 'Please enter a PersonID or press enter to continue', person
\prompt 'Please enter an TransferBankAccountID or press enter to continue', transferbankaccount
\prompt 'Please enter an the AccountNumber or press enter to continue', bankaccountnumber
\prompt 'Please enter an OrderID', orderID

\pset expanded on

WITH Data AS (
  SELECT DISTINCT
  /*1*/  (ARRAY_AGG(DISTINCT COALESCE(lower(OrdersKYCData.Name), lower(E.Name), lower(KYC.Entities.Name), lower(TransferBankAccounts.Name), lower(TransferBankAccounts.kycdata::json->>'name'), CONCAT(lower(OrderAttributes.FirstName),' ',lower(OrderAttributes.LastName)), CONCAT(lower(KYC.PNPOrders.kycdata::json->>'firstname'),' ',lower(KYC.PNPOrders.kycdata::json->>'lastname')) ))) AS Name,
  /*2*/  (ARRAY_AGG(DISTINCT COALESCE(OrdersKYCData.dob, KYC.Entities.dob, (KYC.PnPOrders.kycdata::json->>'dob')::date, TransferBankAccounts.dob, OrderAttributes.dob))) AS DateOfBirth,
  /*3*/  (ARRAY_AGG(DISTINCT COALESCE(OrdersKYCData.gender, KYC.Entities.gender, TransferBankAccounts.gender))) AS Gender,
  /*4*/  (ARRAY_AGG(DISTINCT COALESCE(lower(OrdersKYCData.address), lower(kyc.entities.fulladdress::json->>'address'), lower(E.address), lower(TransferBankAccounts.address), lower(OrderAttributes.address)))) AS Address,
  /*5*/  (ARRAY_AGG(DISTINCT COALESCE(OrdersKYCData.zipcode, kyc.entities.fulladdress::json->>'zipcode', E.zipcode, TransferBankAccounts.zipcode))) AS ZipCode,
  /*6*/  (ARRAY_AGG(DISTINCT COALESCE(lower(OrdersKYCData.City), lower(kyc.entities.fulladdress::json->>'city'), lower(E.City), lower(TransferBankAccounts.city), lower(OrderAttributes.locale)))) AS City,
  /*7*/  (ARRAY_AGG(DISTINCT COALESCE(Upper(OrdersKYCData.Country), Upper(kyc.entities.fulladdress::json->>'country'), Upper(E.Country), Upper(TransferBankAccounts.Country), Upper(Countries.Name)))) AS Country,
  /*8*/  (ARRAY_AGG(DISTINCT COALESCE(replace(replace(TransferBankAccounts.PersonIDs::text,'{',''),'}',''), OrdersKYCData.PersonID, (kyc.PnpOrders.kycdata::json->>'personid'), kyc.entities.personid, E.PersonID, OrderAttributes.NationalIdentificationNumber))) AS PersonID,
  /*9*/  (ARRAY_AGG(DISTINCT COALESCE(TransferBankAccounts.AccountNumber, OrderAttributes.AccountNumber, (kyc.PnpOrders.kycdata::json->'accounts')::text))) AS BankAccounts,
  /*10*/ (ARRAY_AGG(DISTINCT COALESCE(replace(replace(replace(KYC.Entities.phonenumber, '+', ''), ' ', ''), '-',''), replace(replace(replace(OrderAttributes.mobilephone, '+',''), ' ', ''), '-','')))) AS PhoneNumbers,
  /*11*/ (ARRAY_AGG(DISTINCT COALESCE(lower(E.Email), lower(OrderAttributes.Email), lower(kyc.entities.email)))) AS Email
  /*12*/-- (ARRAY_AGG(DISTINCT COALESCE(lower(E.Email), lower(OrderAttributes.Email), lower(kyc.entities.email)))) AS IsRegisteredBlocked
    FROM Orders
    LEFT JOIN Entities E ON (E.EntityID = Orders.EntityID)
    LEFT JOIN BankOrders ON (BankOrders.OrderID = Orders.OrderID)
    LEFT JOIN OrderBankAccounts ON (OrderBankAccounts.OrderID = Orders.OrderID)
    LEFT JOIN TransferBankAccounts ON (TransferBankAccounts.TransferBankAccountID = (COALESCE(BankOrders.TransferBankAccountID, OrderBankAccounts.TransferBankAccountID)))
    LEFT JOIN LATERAL(
      SELECT DISTINCT OrderID
        FROM BankOrders
       WHERE TransferBankAccountID = TransferBankAccounts.TransferBankAccountID AND Datestamp >= now() - interval '24 months'
       UNION
      SELECT DISTINCT orderID
        FROM orderbankaccounts
       WHERE TransferBankAccountID = TransferBankAccounts.TransferBankAccountID AND Datestamp >= now() - interval '24 months'
       UNION
      SELECT DISTINCT orderID
        FROM BankOrderTransfers
       WHERE (ToTransferBankAccountID = TransferBankAccounts.TransferBankAccountID OR FromTransferBankAccountID = TransferBankAccounts.TransferBankAccountID) AND Datestamp >= now() - interval '24 months'
     ) AS OrdersCollection ON TRUE
    LEFT JOIN OrderAttributes ON (OrderAttributes.OrderID = (COALESCE(OrdersCollection.OrderID, Orders.OrderID))) AND (Orderattributes.FirstName IS NOT NULL) AND (OrderAttributes.LastName IS NOT NULL)
    LEFT JOIN Countries ON (Countries.code = OrderAttributes.Country)
    LEFT JOIN OrdersKYCData ON (OrdersKYCData.OrderID = OrdersCollection.OrderID)
    LEFT JOIN kyc.PnpOrders ON (kyc.PnpOrders.OrderID = OrdersCollection.OrderID)
    LEFT JOIN kyc.OrdersEntity  ON (kyc.OrdersEntity.OrderID = OrdersCollection.OrderID)
    LEFT JOIN kyc.Entities ON (kyc.Entities.KYCEntityID = KYC.OrdersEntity.KYCEntityID)
   WHERE (SELECT CASE WHEN NULLIF(:'person','') IS NOT NULL THEN :'person' = ANY(Transferbankaccounts.personIDs)
                      WHEN NULLIF(:'transferbankaccount','') IS NOT NULL THEN TransferBankAccoutns.TransferBankAccoutnnID = :'transferbankaccount'
                      WHEN NULLIF(:'bankaccountnumber','') IS NOT NULL THEN TransferBankAccounts.Accountnumber = :'bankaccountnumber'
                      ELSE Orders.OrderID = :'orderID'  END)
 )
 SELECT DISTINCT
        INITCAP(replace(replace(replace(replace(DATA.name::text,'{',''),'}',''),'"',''),',NULL','')) AS name,
        replace(replace(replace(replace(DATA.dateofbirth::text,'{',''),'}',''),'"',''),',NULL','') AS dateofbirth,
        replace(replace(replace(replace(DATA.gender::text,'{',''),'}',''),'"',''),',NULL','') AS gender,
        INITCAP(replace(replace(replace(replace(DATA.address::text,'{',''),'}',''),'"',''),',NULL','')) AS address,
        UPPER(replace(replace(replace(replace(DATA.zipcode::text,'{',''),'}',''),'"',''),',NULL','')) AS zipcode,
        INITCAP(replace(replace(replace(replace(DATA.city::text,'{',''),'}',''),'"',''),',NULL','')) AS city,
        replace(replace(replace(replace(DATA.country::text,'{',''),'}',''),'"',''),',NULL','') AS country,
        replace(replace(replace(replace(DATA.personid::text,'{',''),'}',''),'"',''),',NULL','') AS personid,
        replace(replace(replace(replace(replace(replace(replace(DATA.bankaccounts::text,'{',''),'}',''),'"',''),',NULL',''),'\\',''),'[',''),']','') AS bankaccounts,
        replace(replace(replace(replace(DATA.phonenumbers::text,'{',''),'}',''),'"',''),',NULL','') AS phonenumber,
        replace(replace(replace(replace(DATA.email::text,'{',''),'}',''),'"',''),',NULL','') AS emailaddress
   FROM DATA
;

--OR ENTER PERSONID
--OR ENTER BANKACCOUNTN NNUMBER

/* Revamp notes:
TransferBankAccounts
accountnumber, iban, balance, personids, personid, name, address, zipcode, city, dob, gender, coutry

Entities
email, personnid, name, address, zipcode, city, country, extendedmobilebankid

OrderAttributes
firstname, lastname, country, accountnumber, email, NationalIdentificationNumber, address, dob, ip, mobilephone

OrdersKYCData
name, dob, personid, gender, address, zipcode, city, coutry, email

autogiro.outgoingmandaterecords
accountnnumber, personid

autogiro.mandateadvicerecords
bankaccountnumber, personid,

autogiro.payers
accountnumber, personId


enduserclientplatforms
os, osversio, browser, browserversion, hardware

browseruseragents
value,

orderfingerprints

sessions
enduserhost (IP)

blockedpersons
personid, reason

bankorders
personid, balance

kyc.pnporders
kycdata {dob, accounts, fullaccountnumber, balance, firstname, lastname}, personid, dob

kyc.entities
personid, firstname, lastname, name, dob, fulladdress, email, phonenumber, geder

kyc.bankentities
name


kyc.endusers
firstname, lastname, name, email
*/
