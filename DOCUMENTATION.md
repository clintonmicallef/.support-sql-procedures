# INTRODUCTION

Support-SQL-Repository is a shared library of SQL Files (Procedures, functions and views) stored in GITHUB. Interactive queries, where the user calls these procedures via aliases and enters any requested parameters.

The purpose behind this is for a user to be able to quickly access and run queries, functions and views that are commonly used. This is done by using Aliases which are set to call a particular SQL file, such as "merchant_entrysteps" would be calling the file: merchant_entrysteps.sql within the local path for support-sql-repository.

SQLQueriesDir is set in the .PSQLRC file to reflect a directory where said file {merchant_entrysteps.sql} would be stored, ex: ```/Users/[username]/support-sql-repository```

The .PSQLRC (_PostgreSQL Run Commands_) file, which is created in the Users' Home Directory, is run upon start-up of the DB environment. Any files and code written to this file are immediately executed upon initialising your Postgres Session.

The Support-SQL-Repository will help the support department gain quick access to regularly-required information, save time in yielding results, export uniform results for better readability and decrease time wasted from typographical type errors and mistakes which arise from 'badly-hacked' queries.

IMP, this does not mean that the SQL language will be less of a requirement for each agent to grasp and gain as a skill. It would be indeed good practice for new / beginner SQL users to start our by writing their own queries as to get a good grasp of the language instead of using SQL Aliases from the Support-SQL-Repository.
The general scope of this project is to have quick and easily accessible GENERALISED queries. Ones which are used for monitoring, general data compilation and so on. Other reporting queries or ones which require specific restrictions (parameters), etc, will have to be written by the individual agent (as per usual job practice).

**The user will read the README.md file where instructions on how to install, clone and use the repository are shared.**





# TECHNICAL SPECIFICATIONS

SQL Files are created as procedural queries, functions or views and pushed to Support-SQL-Repository in GITHUB.

Besides SQL Files the Repository also holds System files.

_PSQL Files_:
```
- init.psql
- import_functions.psql
- import_views.psql
- set_aliases.psql
```

_Shell Files_:
```
- git.sh
- install.sh
- update.sh
```

and a miscellaneous SQL File ```help.sql```

The Repository also stores SQL Files for the creation of _Temporary Tables_ for all 3 classes of SQL Files.


The **init.psql** file is the foundation of this  Project.

This file has 4 purposes:
```
1. Creates temporary tables populated by the data of the SQL files.
2. Launches functions and views (create) to be able to be used in the DB environement.
3. Set aliases based on the data from the temporary tables. (these aliases will be used to call the actual queries)
4. To initialise and update the user's local environment upon DB (psql) login.
```

A help file is also initiated here and assigned an alias to help the user search and select an alias to a particular query.


Upon configuration of this system, the user runs: ```./install.sh```.

This does two primary tasks:
```
1. Creates file .psqlrc for the user within the User's Home folder and populates it according to the information witin init.psql file.
   OR Adds new lines to an already existent .psqlrc file and populates these lines according to the information within the init.psql file.
2. Runs Bash commands for update.psql -> update.sh using the GIT token to fetch and pull updates from the GIT repository.
```


# TECHNICAL FLOW

Repository is downloaded to User's Home Directory as per ```README.md```.

install.sh is run creating or editing the .psqlrc file setting the SQLQueriesDir as the localpath where the repository was saved and setting it to link to the init.psql file.
install.sh also runs commands to update and pull from GIT.

init.psql sets into the .psqlrc file instructions to:
```
- Initialise and update environement
- Prevent disaply of loading notices
- Create temporary tables {to be used by help.sql & set_aliases.sql}
- Import functions and views
- Set aliases
- Displays a menuMenu
```

User runs git_update whenever a commit to the repo is done.

This performs a git pull and re-initialises the environment running init.psql.

This adds the file to  temporary tables.

sets an aliases.

Adds data to help.sql

Since PSQLRC is linked to init, psqlrc is updated and user has access to new file.



# TECHNICAL DIAGRAM/FLOW
![alt text] (https://github.com/lukaszhanusik/support-sql-procedures/blob/documentation/DIAGRAM_FLOW.jpg "diagram_flow")


# REQUIREMENTS

IF (**A**) this is an edit to an already added SQL Procedure / function / View,
  A normal edit and commit to master is to be done.

IF (**B**) this is a new SQL prodecure / function /  view
  A pull request is to be created on a new branch and requested for review.

IF (**C**) fix to an issue (bug)
  If concerning an SQL file, a direct commit to master can be done.
  If concerning a system file, GITHUB system, init process, a pull request is to be created on a new branch and requested for review.

IF (**D**) addition / update of a system file
  A pull request is to be created on a new branch and requested for review.

At no point should a commit disrupt the work flow of users on this repository.

Please follow the guidelines and templates when adding to Support repository.
