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


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'order_iframe_steps');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
