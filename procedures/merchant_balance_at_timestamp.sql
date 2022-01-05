/* Merchant's Balance at a certain date and time */

\prompt 'please enter the processing account', processingaccount
--\prompt 'please enter a currency for the total converted amount', currency
\prompt 'please enter datestamp with timestamp', dateandtime

\set QUIET ON

\pset expanded on

WITH ClosingBalance AS (
  SELECT Users.Username,
         Currency,
         round(Balance*-1,2) AS Balance
    FROM FlagValueAccountingBalancesDaily
   INNER JOIN FlagValues ON (FlagValueAccountingBalancesDaily.FlagValueID = FlagValues.FlagValueID)
   INNER JOIN Users ON (Users.Username = FlagValues.Value)
   WHERE AccountName = 'CLIENT_BALANCES'
     AND Users.Username = :'processingaccount' --- to be declared as PA
     AND Date = (:'dateandtime')::date - interval '1 day' --- to be declared as timestamp
     AND Currency IN (SELECT currency FROM balance(:'processingaccount')) --- to be declared as PA
   ORDER BY Currency,Date
 ),
 AccountLedger AS(
   SELECT Users.Username,
          SUM(round(COALESCE(FXTrades.NewAmount * -1, CASE WHEN FlagValueAccountingTransactions.DebitAccountName = 'CLIENT_BALANCES' THEN -FlagValueAccountingTransactions.Amount ELSE FlagValueAccountingTransactions.Amount END),2)) AS TotalAmount,
          COALESCE(FXTrades.NewCurrency, FlagValueAccountingTransactions.Currency) AS Currency
     FROM FlagValues
    INNER JOIN FlagValueAccountingTransactions ON (FlagValueAccountingTransactions.FlagValueID = FlagValues.FlagValueID)
    INNER JOIN Events ON (Events.EventID = FlagValueAccountingTransactions.EventID)
    INNER JOIN Bindings ON (Bindings.BindID = Events.BindID)
    INNER JOIN Users ON (Users.Username = FlagValues.Value)
     LEFT JOIN Orders ON (Orders.ChainID = Events.ChainID)
     LEFT JOIN FXTrades ON (FXTrades.TransactionID = FlagValueAccountingTransactions.TransactionID)
    WHERE FlagValues.FlagID = CONST_Username_FlagID()
      AND Users.UserID = Get_UserID(:'processingaccount')
      AND (COALESCE(FXTrades.NewCurrency,FlagValueAccountingTransactions.Currency) IN (SELECT currency FROM balance(:'processingaccount'))) --- to be declared as PA = :'currency')
      AND FlagValueAccountingTransactions.RecordDate >= :'dateandtime'::date
      AND FlagValueAccountingTransactions.RecordDate <= :'dateandtime'
      AND 'CLIENT_BALANCES' IN (FlagValueAccountingTransactions.DebitAccountName, FlagValueAccountingTransactions.CreditAccountName)
      AND NOT EXISTS (SELECT 1 FROM FXTrades WHERE FXTrades.FXEventID = FlagValueAccountingTransactions.EventID AND FXTrades.EventID IS NOT NULL)
    GROUP BY 1,3
  )
  SELECT DISTINCT Currencies.processingaccount AS Processing_account,
         Currencies.dateparameter AS date_parameter,
         hstore(array_agg(DISTINCT array[Currencies.Currency::text, Currencies.Balance::text])) AS Currency_Balances,
         totalbalanceeuro AS "total_balance_EUR"
    FROM (
      SELECT ClosingBalance.Username AS processingaccount,
             :'dateandtime'::timestamp AS dateparameter,
             ClosingBalance.Currency::text AS currency,
             (ClosingBalance.Balance + COALESCE(AccountLedger.TotalAmount,0.00)) AS Balance,
             ROUND(sum(fx_readonly(ClosingBalance.Currency, 'EUR', :'dateandtime'::date) * (ClosingBalance.Balance + COALESCE(AccountLedger.TotalAmount,0.00))) over(),2)  AS totalbalanceeuro
        FROM AccountLedger
       RIGHT JOIN ClosingBalance ON ClosingBalance.Username = AccountLedger.Username AND ClosingBalance.Currency = AccountLedger.Currency
         ) Currencies
   GROUP BY 1,2,4
;
