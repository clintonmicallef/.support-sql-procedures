/* Extended information on EntryStep performance including conversion */

\prompt 'Please enter the EntrystepID', entrystepID
\prompt 'Please enter an interval (including unit of time example: 2 hours)', delay
\prompt 'Would you like results per minute or hour?', result

\pset expanded off

WITH Deposit_Monitor AS(
  SELECT date_trunc(:'result', orders.datestamp) as date,
         count(orders.orderid) as total,
         count(case when orders.orderstatusid = 100 then 1 else null end) as done,
         count(case when orders.orderstatusid = 101 then 1 else null end) as timeout,
         count(case when orders.orderstatusid = 102 then 1 else null end) as aborted,
         count(case when orders.orderstatusid = 103 then 1 else null end) as crashed,
         count(case when orders.orderstatusid = 104 then 1 else null end) as limit,
         COUNT(DISTINCT ROW(orders.UserID::text, orders.EndUserID)) AS TotalEusers,
         COUNT(DISTINCT ROW(orders.UserID::text, orders.EndUserID)) FILTER(WHERE Orders.OrderStatusID = 100) AS EusersDONE,
         COUNT(DISTINCT ROW(orders.UserID::text, orders.EndUserID)) FILTER(WHERE Orders.OrderStatusID != 100) AS "eusers!done"
         --,(array_agg(DISTINCT ordersteptypes.name)) as lastorderstep
    FROM orders
    JOIN Ordersteps ON Ordersteps.OrderID = Orders.OrderID AND Ordersteps.NextOrderStepID IS NULL
    JOIN OrderStepTypes ON OrderStepTypes.OrderStepTypeID = OrderSteps.OrderStepTypeID AND OrderStepTypes.OrderTypeid = Orders.OrderTypeID
    JOIN users ON orders.userid=users.userid
   WHERE orders.datestamp >= now() - :'delay'::interval--*/  between '2019-05-12 00:03' and '2019-05-13 10:38'
     AND entrystepid = :'entrystepID'
     --AND Orders.userid = GET_USERID('avanza')
   GROUP BY 1
   ORDER BY 1
 )
 SELECT m.date,
        m.total,
        round((100*m.done/m.total),2) as "%done",
        --done,
        round((100*m.timeout / m.total),2) as "%timeout",
        --timeout,
        round((100*m.aborted / m.total),2) as "%aborted",
        --aborted,
        round((100*m.crashed/m.total),2) as "%crashed",
        --crashed,
        round((100*m.limit/m.total),2) as "%limit",
        --m.limit,
        m.totalEusers,
        m.EusersDONE,
        m."eusers!done"
        --SUM(m.total) over() as total_orders,
        --SUM(Eusers) over() as total_eusers
        --,lastorderstep
   FROM Deposit_Monitor m
  ORDER BY 1;
