#!/bin/bash
scriptDir=$(cd $(dirname "$0"); pwd)

# Configure Git local parameters
gitUserEmail=`id -F | iconv -f utf8 -t ascii//TRANSLIT | awk '{print tolower($1)"."tolower($2)"@trustly.com"}'`
gitUserName=`id -F | iconv -f utf8 -t ascii//TRANSLIT | awk '{print $1,$2}'`

# Declare interactive function to set git config
git_config()
{
  gitUserEmail=$1
  gitUserName=$2
  echo "user.email ${gitUserEmail}"
  echo "user.name ${gitUserName}"
  read -p "Do you want to configure your Git with following parameters: '${gitUserEmail}' (${gitUserName}) ? [Yes/No] " answer

  while true
  do
    case $answer in
     [yY]* ) echo "Git configuration updated"
             git config user.email "${gitUserEmail}"
             git config user.name "${gitUserName}"
             break;;

     [nN]* ) echo "Git configuration unchanged"
             exit;;

     * )     echo "Expecting Yes or No....";
             break ;;
    esac
  done
}

# Declare interactive function to git pull
git_update()
{
  scriptDir=$1
  echo "current path: ${scriptDir}"
  read -p "Do you want to fetch a following repository: '${scriptDir}' ? [Yes/No] " answer

  while true
  do
    case $answer in
     [yY]* ) echo "Updating...."
             /.update.sh
             break;;

     [nN]* ) echo "Change active directory to Git repository to fetch"
             exit;;

     * )     echo "Expecting Yes or No....";
             break ;;
    esac
  done
}

git_config ${gitUserEmail} ${gitUserName}
