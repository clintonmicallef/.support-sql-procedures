:monitor_all_withdrawals
--All Payouts Queue

:monitor_all_deposits
--Deposit orders activity

:get_withdrawal_routes
--Find alternative  payout routes for a bankwithdrawalID

:queue_per_bank
--Queue of a specific EcoSysAccount

:queue_routing_candidates
--All routing options for entire Queue

:set_withdrawal_priority --FUNCTION
--FUNCTION sets retrynow with Parameters: EcoSysAccount, ProcessingAccount, Delay and/or enduser's Receiving Bank

:check_safe_to_retry
--Whether BankWithdrawal is safe to be retried

:plausible_balance
--All deposit of enduser based on PersonID along with Balance of end user's bank account to determine Plausible Balance

:merchant_exposure_limits
--Exoposure Limits of a Merchant

:order_stages
--Events an Order went through

:order_iframe_steps
--All steps, requests and responses done in iFrame

:pa_connections
--Checks whether a connection between one Processing Account and another exists

:entrystep_incident_overview
--Extended information on EntryStep performance including conversion

:merchant_entrysteps
--All entrysteps active for a merchant

:entrystep_issues
--Diagnostics of an EntryStep, Last Order Steps and aggregates

:enduser_device_info
--Information on device end user used during an Order

:graylisted_enduser
--Information on whether an Enduser has failed deposits (graylisted)

:bank_account_balance
--Balance of one of Trustly's bank accounts

:entrystep_deposit_settlement_stats
--Statistical information on deposit settlement times for an entrystep

:gdpr_request
--Provides All information needed for GDPR requirements
--Gets PersonID of an end user
--Not to author: Query needs updating when new KYC model is launched with KYC schema

:check_credit
--Cheks whether credit was pushed by merchant or ourselves
