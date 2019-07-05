#!/bin/bash
# Configure Git local parameters
gitUserEmail=`id -F | iconv -f utf8 -t ascii//TRANSLIT | awk '{print tolower($1)"."tolower($2)"@trustly.com"}'`
gitUserName=`id -F | iconv -f utf8 -t ascii//TRANSLIT | awk '{print $1,$2}'`

echo ${gitUserEmail}
echo ${gitUserName}
# git config --global user.email "YOUR_TRUSTLY_EMAIL@trustly.com"
# git config --global user.name "YOUR_FIRSTNAME YOUR_LASTNAME"
# git config --list

scriptDir=$(cd $(dirname "$0"); pwd)

# (1) prompt user, and read command line argument
read -p "Do you want to update the following repository: '${scriptDir}' ? [Yes/No] " answer

# (2) handle the command line argument we were given
while true
do
  case $answer in
   [yY]* ) echo "Okay, will do"
           break;;

   [nN]* ) exit;;

   * )     echo "Dude, just enter Y or N, please."; break ;;
  esac
done
