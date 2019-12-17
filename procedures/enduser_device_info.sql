/* Information on the device end user used during an Order */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT OrderFingerPrints.OrderID,
       enduserclientplatforms.*,
       browseruseragents.value as useragent,
       IntegrationAuthenticationMethods.Name AS LoginAuthenticationMethod,
       FingerPrints.lastseen
  FROM EnduserClientPlatforms
  JOIN FingerPrints ON (FingerPrints.enduserclientplatformid = EnduserClientPlatforms.enduserclientplatformid)
  LEFT JOIN browseruseragents ON BrowserUserAgents.BrowserUserAgentID = FingerPrints.BrowserUserAgentID
  JOIN OrderFingerPrints ON (OrderFingerPrints.fingerprintid = FingerPrints.fingerprintid)
  JOIN Orders ON (Orders.OrderID = OrderFingerPrints.OrderID)
  LEFT JOIN IntegrationAuthenticationMethods ON (IntegrationAuthenticationMethods.IntegrationAuthenticationMethodID = Orders.IntegrationAuthenticationMethodID)
 WHERE OrderFingerPrints.OrderID = :'orderid';


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'enduser_device_info.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
