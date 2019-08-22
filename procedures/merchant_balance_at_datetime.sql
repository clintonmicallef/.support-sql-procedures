/* Balance of a merchant processing account at a certain time and date */

\prompt 'Please enter the Processing account', processingaccount
\prompt 'Please enter the currency', currency
\prompt 'Please enter a date and time (YYYY-MM-DD HH:MM)', timedate

\pset expanded off

WITH  Parameters(Date,Currency,Username) AS (
VALUES(:'timedate', -- SPECIFIC DATE+TIME
       :'currency', -- CHANGE CURRENCY
       :'processingaccount' --CHANGE USERNAME
       )
 ),
  UserFlagValues AS (
     SELECT Users.Username, FlagValues.FlagValueID
     FROM FlagValues
     INNER JOIN Users ON (Users.Username = FlagValues.Value)
     WHERE FlagValues.FlagID = CONST_Username_FlagID()
 ),
  ClosingBalance AS (
SELECT
FlagValueAccountingBalancesDaily.Date,
FlagValues.Value::text AS Merchant,
FlagValueAccountingBalancesDaily.Currency,
round(FlagValueAccountingBalancesDaily.Balance * -1, 2) AS Balance
FROM FlagValueAccountingBalancesDaily
JOIN FlagValues ON FlagValues.FlagValueID = FlagValueAccountingBalancesDaily.FlagValueID
JOIN Flags ON Flags.FlagID = FlagValues.FlagID
WHERE FlagValueAccountingBalancesDaily.AccountName = 'CLIENT_BALANCES'
AND Flags.Name = 'username'
 ),
 AccountLedger AS (
 SELECT
    ROUND(ClosingBalance.Balance + SUM(InnerQ.InnerAmount),3) AS Balance
 FROM (
     SELECT
         UserFlagValues.Username,
         FlagValueAccountingTransactions.EventID::bigint,
         FlagValueAccountingTransactions.RecordDate,
         CASE
             WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN
                 FlagValueAccountingTransactions.CreditAccountName
             ELSE
                 FlagValueAccountingTransactions.DebitAccountName
         END AS InnerAccountName,
         COALESCE(FXTrades.NewAmount * -1, CASE
             WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN
                 -FlagValueAccountingTransactions.Amount
             ELSE
                 FlagValueAccountingTransactions.Amount
         END) AS InnerAmount,
         COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency,
         Bindings.Name,
         Events.ChainID::bigint
     FROM UserFlagValues
     INNER JOIN FlagValueAccountingTransactions ON (FlagValueAccountingTransactions.FlagValueID = UserFlagValues.FlagValueID)
     INNER JOIN Events ON (Events.EventID = FlagValueAccountingTransactions.EventID)
     INNER JOIN Bindings ON (Bindings.BindID = Events.BindID)
     LEFT JOIN FXTrades ON (FXTrades.TransactionID = FlagValueAccountingTransactions.TransactionID)
     WHERE TRUE
       AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
       AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
       ORDER BY FlagValueAccountingTransactions.RecordDate DESC
 ) AS InnerQ
JOIN ClosingBalance ON ClosingBalance.Merchant = InnerQ.Username AND ClosingBalance.Currency = InnerQ.Currency
LEFT JOIN EventNotes ON EventNotes.EventID = InnerQ.EventID
WHERE ClosingBalance.Date = (SELECT Date FROM Parameters)::date - interval '1 day'
AND InnerQ.RecordDate >= (SELECT  Date FROM Parameters)::date
AND InnerQ.RecordDate < (SELECT Date FROM Parameters)::timestamp
AND ClosingBalance.Currency = (SELECT Currency FROM Parameters)
AND InnerQ.Username = (SELECT Username FROM Parameters)
GROUP BY ClosingBalance.Balance
 )
 SELECT AccountLedger.Balance,
        CASE WHEN AccountLedger.Balance > 0 THEN
        format('POSITIVE_BALANCE FOR PA: %s IN CURRENCY: %s, FOR DATE: %s', Parameters.Username,Parameters.Currency,Parameters.Date)
        ELSE
        format('NEGATIVE_BALANCE FOR PA: %s IN CURRENCY: %s, FOR DATE: %s', Parameters.Username,Parameters.Currency,Parameters.Date) END AS Result
        FROM AccountLedger,Parameters;
