/* Merchant's Account ledger wihout limits */

\prompt 'Please enter the processing account', processingaccount
\prompt 'Please enter a currency', currency
\prompt 'Please enter a date from', datefrom
\prompt 'Please enter a date to', dateto

\set QUIET ON

\pset expanded off

SELECT Users.Username,
       Get_GluePayID_By_EventID(Events.EventID)::text AS GluePayID,
       Get_MessageID_By_EventID(Events.EventID) AS MessageID,
       -- FlagValueAccountingTransactions.EventID::integer,
       FlagValueAccountingTransactions.RecordDate,
       CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN FlagValueAccountingTransactions.CreditAccountName ELSE FlagValueAccountingTransactions.DebitAccountName END AS AccountName,
       round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),2) AS Amount,
       COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency,
       Bindings.Name AS TransactionType,
       Orders.OrderID,
       --ROUND(SUM(round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),8)) over(),2) as Total
       ROUND(SUM(round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),8)) over(order by FlagValueAccountingTransactions.RecordDate asc),2) as RollingTotal
  FROM FlagValues
 INNER JOIN FlagValueAccountingTransactions ON (FlagValueAccountingTransactions.FlagValueID = FlagValues.FlagValueID)
 INNER JOIN Events ON (Events.EventID = FlagValueAccountingTransactions.EventID)
 INNER JOIN Bindings ON (Bindings.BindID = Events.BindID)
 INNER JOIN Users ON (Users.Username = FlagValues.Value)
  LEFT JOIN Orders ON (Orders.ChainID = Events.ChainID)
  LEFT JOIN FXTrades ON (FXTrades.TransactionID = FlagValueAccountingTransactions.TransactionID)
 WHERE FlagValues.FlagID = CONST_Username_FlagID()
   AND Users.UserID = Get_UserID(:'processingaccount')
   --AND Events.ChainID IN (1035269865) -- IN (SELECT ChainID FROM Events JOIN BankDeposits USING (EventID) WHERE BankDepositID IN (4177324776, 2836884290))
   AND (COALESCE(FXTrades.NewCurrency,FlagValueAccountingTransactions.Currency) = :'currency')
   AND FlagValueAccountingTransactions.RecordDate >= :'datefrom'
   AND FlagValueAccountingTransactions.RecordDate <= :'dateto'
   --AND FlagValueAccountingTransactions.EventID = 831074768
   --AND Events.ChainID = 1243817083 -- (SELECT ChainID FROM Events WHERE EventID = 1223786120)
   --AND Events.ChainID =  (SELECT ChainID FROM Events WHERE EventID = 988181685)-- (SELECT ChainID FROM Orders WHERE OrderID = 2040613459)
   --AND LEFT(Bindings.Name, 17) = 'User bank deposit' --AND Bindings.Name ILIKE 'User bank deposit%'
   --AND Events.ChainID = 1002231247
   --AND Orders.OrderID = 1180871722
   --AND round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),2) = 266696.27
   AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
   AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
 ORDER BY FlagValueAccountingTransactions.RecordDate ASC;


 -- Inserts data of this execution in temp table. Copy this data into GoogleDrive. Copy from GoogleDrive ALL data back into another temp table.
 INSERT INTO SupportSQL_UserLogExport VALUES (user, now(), 'merchant_account_ledger.sql');
 \COPY (SELECT * FROM SupportSQL_UserLogExport) TO PROGRAM 'cat >> /Volumes/GoogleDrive/Shared\ drives/Support/useraccesslog.csv' CSV
 \COPY pg_temp.SupportSQL_UserLog FROM '/Volumes/GoogleDrive/Shared drives/Support/useraccesslog.csv' CSV