#!/bin/bash
scriptDir=$(cd $(dirname "$0"); pwd)

psqlrcFile="${HOME}/.psqlrc"
psqlrcLine="\i '${scriptDir}/init.psql'"
psqlrcLineEscaped="\\${psqlrcLine}"

## echo "${scriptDir}/init.psql"
## echo "${psqlrcLine}"
## echo "${psqlrcLineEscaped}"
## echo "${psqlrcFile}"

touch ${psqlrcFile}
grep -qxF "${psqlrcLine}" ${psqlrcFile} || sed -i "" -e $'$ a\\\n'"${psqlrcLineEscaped}" ${psqlrcFile}
echo $'Your psqlrc configuration:\n'"$(cat ${psqlrcFile})"

gitRemote="https://0518c76da1808fe52255329f0d020aa39346b5d5@github.com/lukaszhanusik/support-sql-procedures.git"
## alias updatesql="cd '/Users/lukaszhanusik/.support-sql-procedures' && git status && git pull https://0518c76da1808fe52255329f0d020aa39346b5d5@github.com/lukaszhanusik/support-sql-procedures.git"
### aliasLine='alias updatesql="cd '\''/Users/lukaszhanusik/.support-sql-procedures'\'' && git status && git pull https://0518c76da1808fe52255329f0d020aa39346b5d5@github.com/lukaszhanusik/support-sql-procedures.git"'
## alias updatesql="cd '/Users/lukaszhanusik/.support-sql-procedures' && ./update.sh"
aliasLine='alias updatesql="cd '\''/Users/lukaszhanusik/.support-sql-procedures'\'' && ./update.sh"'

echo ${aliasLine}
