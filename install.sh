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
echo $'Your psqlrc file:\n'"$(cat ${psqlrcFile})"
