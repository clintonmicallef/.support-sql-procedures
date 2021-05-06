#!/bin/bash

## cd $support-sql-procedures.git
## $ git config --global alias.up '!git remote update -p; git merge --ff-only @{u}'
## $ git up
## fatal: no upstream configured for branch 'master'
gitRemote="https://github.com/trustlyinternalsupport/support-sql-procedures.git"

git status && git pull ${gitRemote}

##OLD "https://d07c8b342826921a82212137a34b170493aa34e8@github.com/lukaszhanusik/support-sql-procedures.git"
