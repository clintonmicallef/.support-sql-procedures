/* Monitoring deposit entrystep health (grafana view copy) */

\set QUIET ON

\pset expanded off

SELECT Entrysteps.EntrystepID,
       Workertypes.Name AS Worker,
       Entrysteps.Identifier,
       Countries.Name AS Country,
       Entrysteps.Name,
       --COUNT(*) AS Total,
       --COUNT(*) FILTER(WHERE orderstatusID = 100) AS Done, --last 20 mins
       ROUND( (  (  (COUNT(*) FILTER(WHERE OrderstatusID = 100)) / (SUM(COUNT(*)) over(Partition BY Entrysteps.EntrystepID)) )::numeric ) * 100, 2) AS "%_donerate_20mins",
       doneratelast24hrs.Donerate AS "%_donerate_24hrs",
       (CASE WHEN (doneratelast24hrs.Donerate - ROUND( (  (  (COUNT(*) FILTER(WHERE OrderstatusID = 100)) / (SUM(COUNT(*)) over(Partition BY Entrysteps.EntrystepID)) )::numeric ) * 100, 2)) > 10 THEN 'ALERT' ELSE NULL END) AS Notification
  FROM Orders
  JOIN Entrysteps ON Entrysteps.EntrystepID = Orders.EntrystepID AND Entrysteps.Category = 'deposit'
  JOIN ordersteptypes ON ordersteptypes.ordersteptypeid = entrysteps.ordersteptypeid
  JOIN workertypes ON workertypes.workertypeid = ordersteptypes.ordertypeid
  JOIN Countries ON Countries.CountryID = Entrysteps.CountryID
  LEFT JOIN LATERAL(
    SELECT Orders.EntrystepID, ROUND( (  (  (COUNT(*) FILTER(WHERE OrderstatusID = 100)) / (SUM(COUNT(*)) over(Partition BY Orders.EntrystepID)) )::numeric ) * 100, 2) AS donerate
      FROM Orders
      JOIN Entrysteps OrdersEntrysteps ON OrdersEntrysteps.EntrystepID = Orders.EntrystepID AND OrdersEntrysteps.Category = 'deposit'
     WHERE Orders.Datestamp BETWEEN now() - interval '24 hours' AND now() - interval '20 mins'
     GROUP BY 1
  ) AS doneratelast24hrs ON doneratelast24hrs.EntrystepID = Entrysteps.EntrystepID
 WHERE Orders.Datestamp BETWEEN now() - interval '18 mins' AND now() - interval '2 mins'
 GROUP BY 1,2,3,4,7
 ORDER BY COUNT(*) DESC
;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
\t
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'monitor_deposit_entrysteps');
\t
\i '~/.support-sql-procedures/userlogsetup.psql'
