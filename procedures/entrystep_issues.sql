/* Diagnostics of an EntryStep, Last Order Steps and aggregates */

\prompt 'Please enter an EntrystepID', entrystepID
\prompt 'Please enter an interval (including unit of time example: 2 hours)', timeinput
\prompt 'Please enter a ProcessingAccount or press enter to continue', processingaccount

\set QUIET ON

\pset expanded off

SELECT min(Orders.Datestamp)::timestamp(0),
       max(Orders.Datestamp)::timestamp(0),
       count(DISTINCT ROW(Orders.UserID::text)) AS AffectedMerchants,
       count(*) AS AffectedOrders,
       count(DISTINCT ROW(Orders.UserID::text, Orders.EndUserID)) AS AffectedEndUsers,
       OrderStatuses.Name,
       sum(count(*)) OVER () AS Total,
       round((count(*)::numeric / sum(count(*)) OVER () * 100.00),2) AS Percentage,
       OrderStepTypes.Name AS OrderStepType,
       WorkerTypes.Name AS OrderType
  FROM Orders
  JOIN OrderStatuses ON (OrderStatuses.OrderStatusID = Orders.OrderStatusID)
  JOIN OrderSteps ON (OrderSteps.OrderID = Orders.OrderID AND OrderSteps.NextOrderStepID IS NULL)
  JOIN OrderStepTypes ON (OrderStepTypes.OrderStepTypeID = OrderSteps.OrderStepTypeID)
  JOIN EntrySteps ON (EntrySteps.EntryStepID = Orders.EntryStepID)
  JOIN WorkerTypes ON (WorkerTypes.WorkerTypeID = OrderStepTypes.OrderTypeID)
  JOIN Users ON (Users.UserID = Orders.UserID)
 WHERE Orders.EntryStepID = :'entrystepID'
   AND Orders.Datestamp >= now() - :'timeinput'::interval
   AND (SELECT CASE WHEN NULLIF(:'processingaccount','') IS NOT NULL THEN Users.Username = :'processingaccount' ELSE 'TRUE' END)
   --AND OrderStepTypes.Name IN ('DepositSwedenNDEA.sweden.ndea.step.verify.VerifyAccountStatement')
   --AND OrderStatuses.Name = 'CRASHED'
 GROUP BY 6, 9, 10
 ORDER BY Percentage DESC;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'entrystep_issues');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
