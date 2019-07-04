/*Deposit Orders & Entrystep Activity*/

\prompt 'Please enter an interval (including unit of time example: 2 hours)', input

\pset expanded off

WITH EntrystepsHealth AS(
   SELECT Entrysteps.entrystepid AS EntrystepID,
          Entrysteps.name AS Name,
          countries.name AS Country,
          Entrysteps.priority AS Prio,
          WorkerTypes.Name AS Type,
          Entrysteps.identifier AS Identifier,
          OrderStatuses.name AS Status,
          MAX(OrderSteptypes.name) AS lastorderstep,
          MAX(Orders.datestamp) AS Max_Datestamp,
          COUNT(Orders.orderid) AS Count,
          ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY Entrysteps.entrystepid) * 100) AS Percent,
          COUNT(CASE WHEN OrderStatuses.name != 'DONE' AND orders.datestamp > max THEN 1 ELSE NULL END) AS SinceLastDONE,--count_since_last_done_order
          COUNT(DISTINCT ROW(Orders.UserID::text, Orders.EndUserID)) AS EndUser_Count,
          (CASE WHEN OrderStatuses.name = 'DONE' THEN ROUND(COUNT(*)/SUM(COUNT(*)) over(partition by Entrysteps.entrystepid) * 100) ELSE NULL end) AS done_percent,
          (CASE WHEN OrderStatuses.name != 'DONE' THEN ROUND(COUNT(*)/SUM(COUNT(*)) over(partition by Entrysteps.entrystepid) * 100) ELSE NULL end) AS not_percent
     FROM Orders
     JOIN OrderStatuses ON OrderStatuses.OrderStatusID = Orders.OrderStatusID
     LEFT JOIN OrderSteps ON OrderSteps.OrderID = ORders.ORderID AND OrderSteps.NextOrderStepID IS NULL
     LEFT JOIN OrderStepTypes ON OrderStepTypes.OrderSteptypeID = OrderSteps.OrderSteptypeID
     LEFT JOIN Entrysteps ON Entrysteps.entrystepid=Orders.entrystepid
     LEFT JOIN OrderStepTypes EntrystepType ON EntrystepType.OrderStepTypeID = Entrysteps.OrderStepTypeID
     LEFT JOIN WorkerTypes ON WorkerTypes.WorkerTypeID  = EntrystepType.OrderTypeID
     LEFT JOIN Countries ON countries.countryid=Entrysteps.countryid
     LEFT JOIN LATERAL(
       SELECT EntrystepID, MAX(Datestamp) AS max
         FROM Orders
        WHERE OrderStatusID = 100 --DONE
          AND InitOrderTypeID IN (15, 51, 60) --Deposit, AccountSelector, Paypal
          AND Datestamp >= now() - (:'input')::interval -->>Change time frame<<--
        GROUP BY 1
     ) AS MaxOrder ON MaxOrder.entrystepid=Orders.entrystepid
    WHERE Orders.Datestamp >= now() - (:'input')::interval -->>Change time frame<<--
      AND Orders.InitOrderTypeID IN (15, 51, 60) --Deposit, AccountSelector, Paypal
    GROUP BY 1,2,3,4,5,6,7
  )
  SELECT EntrystepID,
         name,
         country,
         PRIO,
         Type,
         identifier,
         status,
         Count,
         Percent,
         SinceLastDONE,
         (CASE WHEN SUM(not_percent) >= SUM(done_percent) over(partition by EntrystepID) AND SinceLastDONE >= 15 AND status  IN ('WAIT_SERVER') THEN 'SERVER ALERT'
               WHEN SUM(not_percent) >= SUM(done_percent) over(partition by EntrystepID) AND SinceLastDONE >= 10 AND status NOT IN ('WAIT_CLIENT','WAIT_SERVER','WAIT_EVENT') THEN 'ALERT'
               WHEN SUM(not_percent) >= SUM(done_percent) over(partition by EntrystepID) THEN 'MONITOR'
               ELSE NULL END) AS Alert,
         lastorderstep,
         EndUser_Count,
         Max_Datestamp::timestamp(0) AS last_done_order,
         (CASE WHEN done_percent <= 50 then '⬇︎ LOW'
               WHEN done_percent between 50 and 99 then '⬆︎ GOOD'
               WHEN done_percent = 100 then '✔︎ PERFECT'
               WHEN done_percent = 0 then '⚠︎ DOWN!' else NULL end) as conversion
    FROM EntrystepsHealth
   GROUP BY 1,2,3,4,5,6,7,8,9,10,12,13,14, Done_percent, not_percent
   ORDER BY country, name, EntrystepID, identifier, COUNT DESC
;
