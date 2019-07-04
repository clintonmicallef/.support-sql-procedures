#!/bin/bash
scriptDir=$(cd $(dirname "$0"); pwd)

psqlrcFile="${HOME}/.psqlrc"
psqlrcLine="\i '${scriptDir}/init.psql'"
psqlrcLineEscaped="\\${psqlrcLine}"
psqlSetLocalPath="\set local_path_supportsqlprocedures '${scriptDir}'"
psqlSetLocalPathEscaped="\\${psqlSetLocalPath}"

touch ${psqlrcFile}
grep -qxF "${psqlSetLocalPath}" ${psqlrcFile} || sed -i "" -e $'$ a\\\n'"${psqlSetLocalPathEscaped}" ${psqlrcFile}
grep -qxF "${psqlrcLine}" ${psqlrcFile} || sed -i "" -e $'$ a\\\n'"${psqlrcLineEscaped}" ${psqlrcFile}
echo $'Your psqlrc configuration:\n'"$(cat ${psqlrcFile})"

aliasFile="${HOME}/.bash_profile"
aliasName="updatesql"
aliasLine='alias '"${aliasName}"'="cd '\'"${scriptDir}"\'' && ./update.sh"'

alias updatesql="cd ${scriptDir} && ./update.sh"
grep -qxF "${aliasLine}" ${aliasFile} || sed -i "" -e $'$ a\\\n'"${aliasLine}" ${aliasFile}
echo $'Your alias configuration:\n'"$(alias)"
