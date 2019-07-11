# INTRODUCTION

Support-SQL-Procedures is a shared repository (shared library) of SQL files using GITHUB. These are interactive queries, where the user calls these files via aliases and may be prompted to enter any requested parameters.

The purpose is for a user to be able to quickly access and run queries, functions and views that are commonly used. This is done by using aliases which are set to call a particular SQL file where a query, function or view would be written, such as "merchant_entrysteps" would be calling the file: merchant_entrysteps.sql within the local path of the repository.

SQLQueriesDir is set in the .PSQLRC file to reflect a directory where said file {merchant_entrysteps.sql} would be stored, ex: ```/Users/[username]/support-sql-repository```

The .PSQLRC (_PostgreSQL Run Commands_) file, which is created in the Users' Home Directory, is run upon start-up of the DB environment. Any files and code written to this file are immediately executed upon initialising your Postgres Session _(or as in our case, every time init.psql is run thus re-starting the environment)_.

The Support-SQL-Procedures repo will help the support department gain quick access to regularly-required information, export uniform results for better readability and decrease time wasted from typographical type errors and mistakes which arise from 'badly-hacked' queries.

However, it is not the purpose of this project to diminish the SQL skills and abilities of support agents. It would be indeed good practice for new / beginner SQL users to start out by writing their own queries as to get a good grasp of the language instead of using SQL Aliases from the Support-SQL-Procedures.
The general scope of this project is to have quick and easily accessible GENERALISED queries. Ones which are used for monitoring, general data compilation and so on. Other reporting queries or ones which require specific restrictions (parameters), etc, will have to be written by the individual agent (as per usual job practice).

**The user should read the README.md file where instructions on how to install, clone and use the repository are shared.**


# MANUAL

After configuring the repository, perform all Bash configurations, pulling the repository cloning it locally and logging in to Trustly's gluepay Database, the user now has full access to the Support-SQL-Procedures queries.

- Run `:help` without entering a keyword for a full list of aliases and their description.

```
  type    |                alias                |                                                        comment                                                         
----------+-------------------------------------+------------------------------------------------------------------------------------------------------------------------
Procedure | :bank_account_balance               | Show bank account balances
Procedure | :check_credit                       | Checks whether credit was pushed by merchant or ourselves
Procedure | :check_queue                        | Check active withdrawal queues
Procedure | :check_safe_to_retry                | Query returns TRUE or FALSE to whether BankWithdrawal is safe to be retried
Procedure | :enduser_device_info                | Information on the device end user used during an Order
Procedure | :entrystep_deposit_settlement_stats | Statistical information on deposit settlement times for an entrystep
Procedure | :entrystep_incident_overview        | Extended information on EntryStep performance including conversion
Procedure | :entrystep_issues                   | Diagnostics of an EntryStep, Last Order Steps and aggregates
Procedure | :gdpr_request                       | Provides All information needed for GDPR requirements
Procedure | :get_withdrawal_routes              | Find alternative payout routes for a BankWithdrawalID
Procedure | :graylisted_enduser                 | Information on whether an Enduser has failed deposits (graylisted)
Procedure | :merchant_entrysteps                | All entrysteps active for a merchant
Procedure | :merchant_exposure_limits           | Exoposure Limits of a Merchant
Procedure | :monitor_all_deposits               | Deposit Orders & Entrystep Activity
Procedure | :monitor_all_withdrawals            | All Payouts Queue
Procedure | :order_iframe_steps                 | All steps, requests and responses done in iFrame
Procedure | :order_stages                       | Events an Order went through
Procedure | :pa_connections                     | Checks whether a connection of processing accounts for one Processing Account exists
Procedure | :plausible_balance                  | All deposit of enduser based on PersonID along with Balance of end user's bank account to determine Plausible Balance
Procedure | :queue_per_bank                     | Queue of a specific EcoSysAccount
Procedure | :queue_routing_candidates           | All routing options for entire Queue
Procedure | :search_column                      | Search DB Tables using a particular attributes/column
Procedure | :search_table                       | Search DB Tables using a similar table name
Procedure | :set_withdrawal_priority            | Sets RetryNow for withdrawals for parameters: EcoSysAccount, ProcessingAccount, Delay, ToBank
```



- The user can also search for a particular alias by enter a keyword after running `:help` example: _entrystep_ would show all entrystep-related aliases:

```
  type    |                alias                |                                comment                                
----------+-------------------------------------+-----------------------------------------------------------------------
Procedure | :entrystep_deposit_settlement_stats | Statistical information on deposit settlement times for an entrystep
Procedure | :entrystep_incident_overview        | Extended information on EntryStep performance including conversion
Procedure | :entrystep_issues                   | Diagnostics of an EntryStep, Last Order Steps and aggregates
Procedure | :merchant_entrysteps                | All entrysteps active for a merchant
Procedure | :monitor_all_deposits               | Deposit Orders & Entrystep Activity
```


- To run an alias, type or copy the text as per alias column above, therefore,  the name must be preceded by a colon ':' such as: `:entrystep_issues`.

- For some aliases, the user is prompted to enter particular parameters. Here the user must follow the prompted instructions carefully. Failure to do so may result in an error or no results. Example: `Please enter an interval (including unit of time example: 2 hours)`.

- The results will be output in the correct display setting.

- The Support-SQL-Procedures repository is built and maintained by the 2nd Line Team. Please follow the `support-commits` channel on slack. When a new commit is deployed, please run the alias: `:git_update`. This will PULL from the repository thus updating your local repository as per the adjustments done on  master. This can also be requested from you by a 2nd Line team member. The `:git_update` will update your repository and re-initialise the DB environment for a fully updated, workable space.


# RESPONSIBILITIES


There are at least 3 scenarios where you should contact the 2nd Line team with regards to Support-SQL-Procedures repository, mainly when:  

- Discovering a bug
- Discovering the need for a query / function / view
- Discovering the need to adjust an existent procedure or to add a parameter (prompt)

Furthermore, the user, after having read all related documentation, might still have questions. A slack channel will be in place for Direct communication with the admins of this repository to address such questions as well as the 3 above scenarios that might occur to the user.


# NOTICE

**The implementation of Support-SQL-Procedures will manipulate some files and directories on your system.**


- A `.PSQLRC` file will be created in your HOME folder. This is normally hidden (hence the '.'). However, should you already have a `.PSQLRC` file which you are using, it will be manipulated accordingly:
Three lines of _psql_ code will be added to the file.
`\echo Loading ~/.psqlrc`
`\set local_path_supportsqlprocedures '/Users/benjaminschembri/Trustly/support-sql-procedures'`
`\i '/Users/benjaminschembri/Trustly/support-sql-procedures/init.psql'`
Please do not delete or corrupt these three lines. Doing so will disrupt the performance of the repository.
Should you need to add to your `.PSQLRC` file, please add new lines to it without corrupting / overwriting the three lines mentioned above.

- Your `.BASH_PROFILE` file  will also be manipulated. A script such as: `alias updatesql="cd '/Users/benjaminschembri/.support-sql-procedures' && ./update.sh"` will be added in a new line to this file. Again, please do not delete or corrupt this script as it will result in a failure / error during your daily  workflow using Support-SQL-Procedures.

**FINALLY**

- The actual repository will be cloned and saved in your home folder as: `.support-sql-procedures` (again a hidden folder). Obviously, whatever  you do, do not remove or tamper at all with this folder or its contents. Doing so might corrupt your cloned repository and your ability to use it.


---
_Thank you_
_Support 2nd Line_
