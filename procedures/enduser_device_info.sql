/* Information on the device end user used during an Order */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT OrderFingerPrints.OrderID,
       enduserclientplatforms.*,
       browseruseragents.value as useragent,
       IntegrationAuthenticationMethods.Name AS LoginAuthenticationMethod,
       OrderFingerPrints.enduserhost,
       FingerPrints.lastseen
  FROM EnduserClientPlatforms
  JOIN FingerPrints ON (FingerPrints.enduserclientplatformid = EnduserClientPlatforms.enduserclientplatformid)
  LEFT JOIN browseruseragents ON BrowserUserAgents.BrowserUserAgentID = FingerPrints.BrowserUserAgentID
  JOIN OrderFingerPrints ON (OrderFingerPrints.fingerprintid = FingerPrints.fingerprintid)
  JOIN Orders ON (Orders.OrderID = OrderFingerPrints.OrderID)
  LEFT JOIN IntegrationAuthenticationMethods ON (IntegrationAuthenticationMethods.IntegrationAuthenticationMethodID = Orders.IntegrationAuthenticationMethodID)
 WHERE OrderFingerPrints.OrderID = :'orderid';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'enduser_device_info');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
