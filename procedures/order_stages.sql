/* Events an Order went through */

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded off

SELECT Orders.OrderID,
       Events.Datestamp::timestamp(0),
       BankLedger.BankLedgerID, events.currency, events.amount,
       Bindings.Name AS Binding
  FROM Events
  JOIN Bindings ON (Bindings.BindID = Events.BindID)
  LEFT JOIN BankLedger ON (BankLedger.EventID = Events.EventID AND Events.EventTypeID IN (302,1))
  LEFT JOIN Orders ON (Orders.ChainID = Events.ChainID)
 WHERE Events.ChainID = (SELECT ChainID FROM Orders WHERE OrderID = :'orderid')
 ORDER BY 1, 2 DESC;


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'order_stages.sql');
\COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
\COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV
