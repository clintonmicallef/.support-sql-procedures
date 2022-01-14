/* Find an auto-settlement that included transactions related to a specific order. */

\prompt '\nEnter OrderID: ' orderid
\echo ''

\set QUIET ON
\pset expanded ON

SELECT
   Users.Username,
   Orders.OrderID,
   FlagValueAccountingTransactions.RecordDate::TIMESTAMP(0),
   Bindings.DisplayName AS "type",
   COALESCE(
      FXTrades.NewAmount * -1,
      CASE
         WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN - FlagValueAccountingTransactions.Amount
         ELSE FlagValueAccountingTransactions.Amount
      END
   ) AS Amount,
   FlagValueAccountingTransactions.Currency,
   CASE
      WHEN SettlementBatches.SettlementBatchID IS NOT NULL THEN SettlementBatches.SettlementBatchID::TEXT
      ELSE 'No auto-settlement calculation included this transaction!'
   END AS settlementbatchid,
   SettlementBatches.SettlementDate,
   Settlements.BankWithdrawalID
FROM
   FlagValueAccountingTransactions
   INNER JOIN Events ON Events.EventID = FlagValueAccountingTransactions.EventID
   INNER JOIN Bindings ON Bindings.BindID = Events.BindID
   LEFT JOIN FXTrades ON FXTrades.TransactionID = FlagValueAccountingTransactions.TransactionID
   LEFT JOIN Orders ON Events.ChainID = Orders.ChainID
   JOIN Users ON Orders.UserID = Users.UserID
   LEFT JOIN Autosettle.SettlementBatches ON SettlementBatches.UserID = Orders.UserID AND (FlagValueAccountingTransactions.RecordDate BETWEEN SettlementBatches.StartTimestamp AND EndTimestamp) AND FlagValueAccountingTransactions.Currency = SettlementBatches.Currency
   LEFT JOIN Autosettle.Settlements ON Settlements.SettlementBatchID = SettlementBatches.SettlementBatchID
WHERE
   Orders.OrderID = :'orderid';