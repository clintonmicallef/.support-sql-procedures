/* Merchant's Account ledger wihout limits */

\prompt 'Enter processing account name: ' processingaccount
\prompt 'Enter date from: ' fromdate
\prompt 'Enter date to: ' todate
\prompt 'Enter currency: ' currency

\set QUIET ON

\pset expanded off

SELECT Users.UserName::text,
       f.GluePayID,
       f.MessageID,
       f.Datestamp,
       Censor_Entercash_Descriptor(f.AccountName)::varchar,
       f.Amount,
       f.Currency,
       Censor_Entercash_Descriptor(f.TransactionType)::varchar,
       f.OrderID
   FROM Get_Client_Balances_Ledger(:'processingaccount', :'fromdate', :'todate', :'currency', (SELECT CASE WHEN IntegrationOwningUser.integrationtypeid IS NOT NULL THEN TRUE ELSE FALSE END FROM IntegrationOwningUser WHERE IntegrationOwningUser.UserID = get_userid(:'processingaccount'))) f
   JOIN Users ON Users.UserID = f.UserID;
