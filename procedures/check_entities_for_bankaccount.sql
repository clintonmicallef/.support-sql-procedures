/* Checks different entities (names) for same transferbankaccountid (bankaccount) */

\prompt 'Please enter a TransferBankAccountID', transferbankaccountID

\set QUIET ON

\pset expanded off

SELECT kyc.entities.kycentityid,
       kyc.entities.publicentityid,
       kyc.entities.name,
       kyc.entities.dob,
       kyc.entities.fulladdress,
       kyc.entities.personid,
       bankentitiesaccounts.bankentityid,
       bankentitiesaccounts.transferbankaccountid,
       Transferbankaccounts.accountnumber,
       Transferbankaccounts.banknumber,
       bankentitiesaccounts.datestamp::timestamp(0),
       bankentitiesaccounts.lastused::timestamp(0)
  FROM kyc.bankentitiesaccounts
  JOIN kyc.bankentities on bankentities.bankentityid=bankentitiesaccounts.bankentityid
  JOIN kyc.entities on entities.kycentityid = bankentities.kycentityid
  JOIN Transferbankaccounts ON TransferBankAccounts.TransferBankAccountID = bankentitiesaccounts.transferbankaccountID
 WHERE kyc.bankentitiesaccounts.transferbankaccountid = :'transferbankaccountID'
 ;

\echo NOTE: If different names appear, very possible its a shared account.
