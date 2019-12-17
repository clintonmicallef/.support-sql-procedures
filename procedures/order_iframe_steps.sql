/* All steps, requests and responses done in iFrame */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT OrderSteps.OrderID,
       OrderSteps.OrderStepID,
       OrderSteps.Datestamp,
       OrderSteps.OrderStepTypeID,
       OrderStepTypes.Name AS OrderStepType,
       OrderSteps.OrderTypeID,
       json_pretty(regexp_replace(OrderSteps.ServerRequest,'\s\s','','g')) AS ServerRequest,
       json_pretty(regexp_replace(OrderSteps.ClientResponse,'\s\s','','g')) AS ClientResponse
  FROM OrderSteps
  JOIN OrderStepTypes ON (OrderStepTypes.OrderStepTypeID = OrderSteps.OrderStepTypeID)
 WHERE OrderSteps.OrderID = :'orderid'
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'order_iframe_steps.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
