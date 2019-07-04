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

aliasFile="${HOME}/.bash_profile"
aliasLine='alias updatesql="cd '\''/Users/lukaszhanusik/.support-sql-procedures'\'' && ./update.sh"'

## alias updatesql="cd '/Users/lukaszhanusik/.support-sql-procedures' && ./update.sh"

grep -qxF "${aliasLine}" ${aliasFile} || sed -i "" -e $'$ a\\\n'"${aliasLine}" ${aliasFile}
echo $'Your psqlrc configuration:\n'"$(cat ${aliasFile})"
