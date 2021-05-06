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

# Run git_config() and try to set the user details
git_config ${gitUserEmail} ${gitUserName}



# Declare function to setup remotes for the repository
git_remote()
{
  # Export your username (assuming you have the same on all platforms)
  # On Trustly GitHub, user.name should be set as Firstname Lastname, this can be changed for each repository locally or set globally
  GIT_USER_NAME=$USER
  git remote add origin-github https://${GIT_USER_NAME}@github.com/trustlyinternalsupport/support-sql-procedures.git
  git remote add origin-bitbucket https://${GIT_USER_NAME}@bitbucket.org/TrustlySupport/support-sql-procedures.git
  git remote set-url origin --add https://${GIT_USER_NAME}@bitbucket.org/TrustlySupport/support-sql-procedures.git
  # Display if all remotes. You should see 2 push (GitHub, BitBucket) and only 1 fetch (GitHub)
  git remote -v
    # Config should look like this
    # origin	https://github.com/lukaszhanusik/support-sql-procedures.git (fetch)
    # origin	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (push)
    # origin	https://github.com/lukaszhanusik/support-sql-procedures.git (push)
    # origin-bitbucket	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (fetch)
    # origin-bitbucket	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (push)
    # origin-github	https://lukaszhanusik@github.com/lukaszhanusik/support-sql-procedures.git (fetch)
    # origin-github	https://lukaszhanusik@github.com/lukaszhanusik/support-sql-procedures.git (push)
}

##OLD
##git remote add origin-github https://${GIT_USER_NAME}@github.com/lukaszhanusik/support-sql-procedures.git
##git remote add origin-bitbucket https://${GIT_USER_NAME}@bitbucket.org/TrustlySupport/support-sql-procedures.git
##git remote set-url origin --add https://${GIT_USER_NAME}@bitbucket.org/TrustlySupport/support-sql-procedures.git
### Display if all remotes. You should see 2 push (GitHub, BitBucket) and only 1 fetch (GitHub)
##git remote -v
##  # Config should look like this
##  # origin	https://github.com/lukaszhanusik/support-sql-procedures.git (fetch)
##  # origin	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (push)
##  # origin	https://github.com/lukaszhanusik/support-sql-procedures.git (push)
##  # origin-bitbucket	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (fetch)
##  # origin-bitbucket	https://lukaszhanusik@bitbucket.org/TrustlySupport/support-sql-procedures.git (push)
##  # origin-github	https://lukaszhanusik@github.com/lukaszhanusik/support-sql-procedures.git (fetch)
##  # origin-github	https://lukaszhanusik@github.com/lukaszhanusik/support-sql-procedures.git (push)
##}
