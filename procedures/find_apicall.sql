/* Find an API call */

\prompt 'Please enter an OrderID', orderid
\prompt 'Please enter the Method', method
\prompt 'Please enter the Processing Account', processingaccount
\prompt 'Please enter the Date (YYYY-MM-DD)', orderdate

\set QUIET ON

\pset expanded on

SELECT APICallID,
      Method,
      json_pretty(data) AS Data_Received,
      json_pretty(signedresult) AS Data_Sent,
      host,
      datestamp,
      username
 FROM APICalls
WHERE Method = :'method' AND
      Username = :'processingaccount' AND
      Datestamp >= :'orderdate' AND
      ((SignedResult::json->'data'->>'orderid')::bigint = :'orderid' OR (ResultData::json->>'orderid')::bigint = :'orderid')
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'find_apicall.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
