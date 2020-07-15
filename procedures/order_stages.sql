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


-- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table for viewing.
SELECT pg_temp.user_log_function(user::text, now()::timestamp , 'order_stages');
\i '~/.support-sql-procedures/userlogsetup.psql'
