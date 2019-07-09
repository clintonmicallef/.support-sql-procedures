# INTRODUCTION

Support-SQL-Procedures is a repository (shared library) of SQL files stored in GITHUB. These are interactive queries, where the user calls these files via aliases and may be prompted to enter any requested parameters.

The purpose is for a user to be able to quickly access and run queries, functions and views that are commonly used. This is done by using aliases which are set to call a particular SQL file where a query, function or view would be written, such as "merchant_entrysteps" would be calling the file: merchant_entrysteps.sql within the local path of the repository.

SQLQueriesDir is set in the .PSQLRC file to reflect a directory where said file {merchant_entrysteps.sql} would be stored, ex: ```/Users/[username]/support-sql-repository```

The .PSQLRC (_PostgreSQL Run Commands_) file, which is created in the Users' Home Directory, is run upon start-up of the DB environment. Any files and code written to this file are immediately executed upon initialising your Postgres Session _(or as in our case, everytime init.psql is run thus re-starting the environment)_.

The Support-SQL-Procedures repo will help the support department gain quick access to regularly-required information, export uniform results for better readability and decrease time wasted from typographical type errors and mistakes which arise from 'badly-hacked' queries.

However, it is not the purpose of this project to diminish the SQL skills and abilities of support agents. It would be indeed good practice for new / beginner SQL users to start out by writing their own queries as to get a good grasp of the language instead of using SQL Aliases from the Support-SQL-Procedures.
The general scope of this project is to have quick and easily accessible GENERALISED queries. Ones which are used for monitoring, general data compilation and so on. Other reporting queries or ones which require specific restrictions (parameters), etc, will have to be written by the individual agent (as per usual job practice).

**The user should read the README.md file where instructions on how to install, clone and use the repository are shared.**


# TECHNICAL SPECIFICATIONS

SQL Files are created as procedural queries, functions or views and pushed to Support-SQL-Procedures repository in GITHUB.

Besides SQL Files the Repository also holds 'System' files such as...

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

and a procedural-user-assistant SQL File: ```help.sql```

The repository also stores SQL Files for the creation of _Temporary Tables_ for all 3 classes of SQL Files, temoporary table from which data can be then extracted and manipulated for better integration.

The **init.psql** file is the back-bone of this  Project and is called from the ```.PSQLRC``` file.

This file has 4 purposes:
```
1. Assigns particular aliases for help and environment setup  
2. Creates temporary tables populated by the data of the SQL files.
3. Launches functions and views (create) to be able to be used in the DB environment.
4. Set aliases based on the data from the temporary tables. (these aliases will be used to call the actual queries)
5. Sets commands for better user prompts during the initialisation of the session.
6. Displays a Menu upon start-up.
```

The help file initiated here _(init.psql)_ runs the ```help.sql``` file which returns prompts to help the user search and select an alias for a particular query.

Upon configuration of this repository, the user runs: ```./install.sh```.

This does two primary tasks:
```
1. Creates file .psqlrc for the user within the User's Home folder and populates it according to the information witin init.psql file.
   OR Adds new lines to an already existent .psqlrc file and populates these lines according to the information within the init.psql file.
2. Adds Bash commands to the `.bash_profile` in the user's home folder for update.psql -> update.sh using the GIT token to fetch and pull updates from the GIT repository.
```


# TECHNICAL FLOW

Repository is downloaded to User's Home Directory following the instructions in  ```README.md```.

The user runs ```install.sh```which creates a new ```.PSQLRC``` file  if none exist, or adds lines to an existent ```.PSQLRC``` file.
It sets the SQLQueriesDir as the localpath where the repository was saved and sets a link ```\i``` to the ```init.psql``` file from where the commands will  be run.
```install.sh``` also adds bash commands to the `.bash_profile` file with commands to update and pull from the GIT repository using `update.psql` -> `update.sh`.

```init.psql``` contains code to:

**Initialise and update environement, including help facility.**
Here ```\set``` is hard coded for fixed "system" files.
Example alias: `git_update` which the user runs to pull from the GIT repository and re-runs the `.PSQLRC` file whenever a new commit has been deployed.

**Create temporary tables.**
Here we set a link to the 'Tables' folder within the repository and run the files within. These files create tables are populated by collecting the data from the repository's folders (/procedures, /functions, /views).
_These temporary tables are an essential part of the repository and will be used by other scripts._

**Import functions and views**
Any function or view created are run here. We again set an import link (`\i`) to the two files: `import_functions.psql` and `import_views.psql` which in turn, collect data from the temporary tables and formats the literals in such a way to create another set of import links...
{`\ir 'functions/get_bank_account_balance.sql'`}.
The result calls the file within the Functions or Views Folder as can be seen above and runs the code within, thus creating the functions and/or views added to the folders.

**Set aliases**
Linking to `set_aliases.psql`, which in turn runs:
{`SELECT format('\set %s ''\\i %s''', substring(FileName, '(.*)\.sql$'), format('%s/%s/%s', :'local_path_supportsqlprocedures', 'procedures', FileName)) FROM SupportSQL_Procedures;
`},
and outputs a string such as:
{`\set bank_account_balance '\\i /Users/benjaminschembri/.support-sql-procedures/procedures/bank_account_balance.sql'`}.
As `init.psql` is referred from the `.PSQLRC` file, these `\set` assignments are linked here thus creating aliases referring to the particular SQL file within the repository.

**Displays a start-up Menu**


# REQUIREMENTS

-
A Procedure / Function / View is to be added as a new file within the respective folder.
-
The code is to be written following the guidelines and templates as per **Support 2nd Line** Confluence when adding to files to Support-SQL-Procedures repository.
-
Pull requests should be used according to the Repository owner's **workflow guidelines**
-
At no point should a commit directly to Master disrupt the work flow of users on this repository.


# TECHNICAL DIAGRAM/FLOW
Please see file: `DIAGRAM_FLOW.jpg` in the repo.
