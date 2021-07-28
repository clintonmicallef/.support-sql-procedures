/* View all details pertaining to a deposit order */
--by: chris swing

\prompt 'Please enter an OrderID', orderid

\set QUIET ON

\pset expanded on

SELECT
    o.DateStamp::timestamp(0) AS initiated,
    o.OrderID,
    t.TransferID,
    o.MessageID,
    o.EndUserID,
    '--------------------' AS "---------",
    CASE
        WHEN os.Name IN('CRASHED','ABORTED','LIMIT','TIMEOUT') THEN CONCAT (os.Name,' on LastStep: ',lost.Name)
        ELSE os.Name
    END AS "Status",
    ts.Name AS transferstate,
    '--------------------' AS "---------",
    CASE
        WHEN o.PaymentCurrency <> o.ApiCurrency THEN CONCAT ('API: ',o.ApiAmount,' ',o.ApiCurrency,' | Payment: ',o.PaymentAmount,' ',o.PaymentCurrency)
        ELSE CONCAT (o.ApiAmount,' ',o.ApiCurrency)
    END AS "Amount",
    CONCAT (fba.AccountNumber,' | ',fba.Name) Sender,
    b.Name AS bank_code,
    o.EntryStepID,
    ba.EcoSysAccount,
    u.UserName,
    psp.PspMerchant,
    '--------------------' AS "---------",
    CASE
        WHEN Credit.DeliveryState IS NOT NULL THEN CONCAT (Credit.ApiMethod,' | ',Credit.DeliveryState,' | ',Credit.DateStamp::timestamp(0))
        WHEN Cancel.DeliveryState  IS NOT NULL THEN CONCAT (Cancel.ApiMethod,' | ',Cancel.DeliveryState,' | ',Cancel.DateStamp::timestamp(0))
        WHEN Debit.DeliveryState  IS NOT NULL THEN CONCAT (Debit.ApiMethod,' | ',Debit.DeliveryState,' | ',Debit.DateStamp::timestamp(0))
        WHEN Account.DeliveryState  IS NOT NULL THEN CONCAT (Account.ApiMethod,' | ',Account.DeliveryState,' | ',Account.DateStamp::timestamp(0))
    END AS "Notification",
    '--------------------' AS "---------",
    CASE
        WHEN os.Name IN ('CRASHED','ABORTED','LIMIT','TIMEOUT') THEN CONCAT ('Settled DP: ',o.RefundSettledDeposits,' | Credit After Cancel: ',u.AllowCreditAfterCancel,' | ',qr.State)
    END AS "Refund",
    CASE
        WHEN risk.DecisionLog.reason IS NOT NULL THEN CONCAT (risk.DecisionLog.reason,' (',risk.DecisionLog.data->>'DepositLimit',') | TransferState: ',risk.DecisionLog.data->>'TransferState')
    END AS "RISK"
FROM orders o
    JOIN users u USING (UserID)
    JOIN entrysteps es USING (EntryStepID)
    JOIN usercategories uc USING (UserCategoryID)
    JOIN orderstatuses os USING (OrderStatusID)
    LEFT JOIN transfers t ON o.orderid = t.orderid AND t.transfertypeid = 1
    LEFT JOIN bankordertransfers bot USING (transferid)
    LEFT JOIN transferbankaccounts fba ON fba.transferbankaccountid = bot.fromtransferbankaccountid
    LEFT JOIN transferbankaccounts tba ON tba.transferbankaccountid = bot.totransferbankaccountid
    LEFT JOIN bankaccounts ba ON ba.transferbankaccountid = bot.totransferbankaccountid AND ba.currency = t.currency
    LEFT JOIN banks b USING (BankID)
    LEFT JOIN transferstates ts USING (transferstateid)
    LEFT JOIN risk.decisionlog ON o.orderID = risk.decisionlog.orderID
    LEFT JOIN queuedrefunds qr ON o.orderID = qr.orderID
    LEFT JOIN Notifications Credit ON Credit.OrderID = o.OrderID AND Credit.ApiMethod = 'credit'
    LEFT JOIN Notifications Cancel ON Cancel.OrderID = o.OrderID AND Cancel.ApiMethod = 'cancel'
    LEFT JOIN Notifications Debit ON Debit.OrderID = o.OrderID AND Debit.ApiMethod = 'debit'
    LEFT JOIN Notifications Account ON Account.OrderID = o.OrderID AND Account.ApiMethod = 'account'
    LEFT JOIN orderattributes oa ON o.orderID = oa.orderID
    LEFT JOIN pspmerchants psp USING (PspMerchantID)
    LEFT JOIN ordersteps los ON los.orderid = o.orderid AND los.nextorderstepid IS NULL
    LEFT JOIN ordersteptypes lost ON lost.ordersteptypeid = los.ordersteptypeid
WHERE o.OrderID = :'orderid'
;
