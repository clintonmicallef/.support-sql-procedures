#!/bin/bash
scriptDir=$(cd $(dirname "$0"); pwd)

# Set variables to add with new lines to .psqlrc
psqlrcFile="${HOME}/.psqlrc"
psqlrcLine="\i '${scriptDir}/init.psql'"
psqlrcLineEscaped="\\${psqlrcLine}"
psqlSetLocalPath="\set local_path_supportsqlprocedures '${scriptDir}'"
psqlSetLocalPathEscaped="\\${psqlSetLocalPath}"

# Create ~/.psqlrc file if does not exist. Add below lines at the end of the file
touch ${psqlrcFile}
echo "\timing" >> ${psqlrcFile}

# Add line \set local_path_supportsqlprocedures '${scriptDir}'
grep -qxF "${psqlSetLocalPath}" ${psqlrcFile} || sed -i "" -e $'$ a\\\n'"${psqlSetLocalPathEscaped}" ${psqlrcFile}

# Add line \i '${scriptDir}/init.psql'
grep -qxF "${psqlrcLine}" ${psqlrcFile} || sed -i "" -e $'$ a\\\n'"${psqlrcLineEscaped}" ${psqlrcFile}

# Print your configuration
echo $'Your psqlrc configuration:\n'"$(cat ${psqlrcFile})"

# Set variables to add with new lines to .bash_profile
aliasFile="${HOME}/.bash_profile"
aliasName="updatesql"
aliasLine='alias '"${aliasName}"'="cd '\'"${scriptDir}"\'' && ./update.sh"'

# Set alias updatesql
alias updatesql="'cd ${scriptDir} && ./update.sh'"

# Add line alias updatesql="cd ${scriptDir} && ./update.sh"
grep -qxF "${aliasLine}" ${aliasFile} || sed -i "" -e $'$ a\\\n'"${aliasLine}" ${aliasFile}

# Print your configuration
echo $'Your alias configuration:\n'"$(alias)"
