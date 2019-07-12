GRAYLIST

select case when eps.balance IS NOT NULL THEN 'YES'::text ELSE 'NO'::text END AS past_failed from orders o join bankorders bo on bo.orderid=o.orderid join eventnamechainbalancespersonsummary eps on eps.personid=bo.personid where o.orderid= 2421105482 and eps.transferstateid=8 and eps.balance>0 limit 1;

SELECT Users.Username,
    EventNameChainBalances.PersonID,
    min(Transfers.ModificationDate),
    max(Transfers.ModificationDate),
    array_agg(Transfers.OrderID) AS OrderIDs,
    EventNameChainBalances.Currency,
    EventNameChainBalances.Balance
 FROM EventNameChainBalances
 JOIN Users ON (EventNameChainBalances.UserID = Users.UserID)
 JOIN Transfers ON (Transfers.EventNameChainBalanceID = EventNameChainBalances.EventNameChainBalanceID)
 WHERE EventNameChainBalances.TransferStateID = 8 -- FAILED
  AND EventNameChainBalances.EventNameChainID IN (SELECT EventNameChainID FROM EventNameChains WHERE Name ~ '^Pending .+ (Cancel|Debit)$')
  AND EventNameChainBalances.PersonID = ANY(Get_Related_PersonIDs(Get_Transfer_PersonID(_TransferID := 1517074173)))
 GROUP BY 1, 2, 6, 7 ;



EXPOSURE LIMIT

SELECT exposurelimitlogid,orderid,amount,currency,round(consumedlimit,2) AS consumedlimit,round(maxlimit,2) AS maxlimit,datestamp::timestamp(0), exposurelimitid,limittype FROM exposurelimitlog WHERE orderid IN (3943120205) AND limittype ILIKE '%PER_PERSON%';

ALL PAYPAL


Order Parameters
Deposit Entrystep Monitoring
OrderStep Checking (iframe)

Amount of deposits per Bank Account (bankorders)
Enduser Activity using AccountNUmber / PersonID / Name
Balance of end user bank account
Search for table
Order Debug
Retrying a withdrawal
Reused Reference Number
Check withdrawal
Bankdeposits for G1s
Deposit Settlement Account
Graylisted
Exposure limit
Plausible balance
Decision Log
Risk



Please note that payin, payout process works as follows:
