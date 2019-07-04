/*Information on device end user used during an Order*/

\prompt 'Please enter an OrderID', orderid

\pset expanded on

SELECT OrderFingerPrints.OrderID,
       enduserclientplatforms.*,
       browseruseragents.value as useragent,
       FingerPrints.lastseen
  FROM EnduserClientPlatforms
  JOIN FingerPrints ON (FingerPrints.enduserclientplatformid = EnduserClientPlatforms.enduserclientplatformid)
  LEFT JOIN browseruseragents ON BrowserUserAgents.BrowserUserAgentID = FingerPrints.BrowserUserAgentID
  JOIN OrderFingerPrints ON (OrderFingerPrints.fingerprintid = FingerPrints.fingerprintid)
 WHERE OrderFingerPrints.OrderID = :'orderid';
