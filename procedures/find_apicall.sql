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
      json_pretty(COALESCE(signedresult::text,resultdata::text)) AS Data_Sent,
      host,
      datestamp,
      username
 FROM APICalls
WHERE Method = :'method' AND
      Username = :'processingaccount' AND
      Datestamp >= :'orderdate' AND
      ((SignedResult::json->'data'->>'orderid')::bigint = :'orderid' OR (ResultData::json->>'orderid')::bigint = :'orderid')
;
