/*Events an Order went through*/

\prompt 'Please enter an OrderID', orderid

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
