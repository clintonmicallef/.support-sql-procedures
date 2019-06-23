/*Creates TEMP Table supportsqlaliases and inserts Valies
  Must be in psqlrc file*/

DROP TABLE supportsqlaliases;
CREATE TEMP TABLE supportsqlaliases(
  category text[3] NOT NULL,
  aliasname character varying NOT NULL,
  comment text
);
INSERT INTO supportsqlaliases (category, aliasname, comment)
VALUES
 ('{withdrawals}', 'monitor_all_withdrawals', 'All Payouts Queue'),
 ('{deposits}', 'monitor_all_deposits', 'Deposit orders activity'),
 ('{withdrawals}', 'get_withdrawal_routes', 'Find alternative  payout routes for a bankwithdrawalID'),
 ('{withdrawals}', 'queue_per_bank', 'Queue of a specific EcoSysAccount'),
 ('{withdrawals}', 'queue_routing_candidates', 'All routing options for entire Queue'),
 ('{withdrawals}', 'set_withdrawal_priority', 'FUNCTION sets retrynow with Parameters, EcoSysAccount, ProcessingAccount, Delay and/or endusers Receiving Bank'),
 ('{withdrawals}', 'check_safe_to_retry', 'Whether BankWithdrawal is safe to be retried'),
 ('{enduser}', 'plausible_balance', 'All deposit of enduser based on PersonID along with Balance of end users bank account to determine Plausible Balance'),
 ('{merchant}', 'merchant_exposure_limits', 'Exoposure Limits of a Merchant'),
 ('{orders}', 'order_stages', 'Events an Order went through'),
 ('{orders}', 'order_iframe_steps', 'All steps, requests and responses done in iFrame'),
 ('{merchant}', 'pa_connections', 'Checks whether a connection between one Processing Account and another exists'),
 ('{entrysteps}', 'entrystep_incident_overview', 'Extended information on EntryStep performance including conversion'),
 ('{merchant, entrysteps}', 'merchant_entrysteps', 'All entrysteps active for a merchant'),
 ('{entrysteps}', 'entrystep_issues', 'Diagnostics of an EntryStep, Last Order Steps and aggregates'),
 ('{enduser}', 'enduser_device_info', 'Information on device end user used during an Order'),
 ('{enduser}', 'graylisted_enduser', 'Information on whether an Enduser has failed deposits (graylisted)'),
 ('{bankaccounts}', 'bank_account_balance', 'Balance of one of Trustlys bank accounts'),
 ('{entrystep}', 'entrystep_deposit_settlement_stats', 'Statistical information on deposit settlement times for an entrystep'),
 ('{enduser}', 'gdpr_request', 'Provides All information needed for GDPR requirements'),
 ('{deposit}', 'check_credit', 'Cheks whether credit was pushed by merchant or ourselves')
;
