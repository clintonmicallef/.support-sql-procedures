# Support SQL Stored Procedures

Version available externally from [GitHub Gist](https://gist.github.com/lukaszhanusik/934accefc993d7d3d2bf04190ccf5087)

## Install Git

There are several ways to install **Git** on a Mac. In fact, if you've installed **Xcode** (or Xcode Command Line Tools), Git may already be installed. To find out, open brand new **terminal** window (outside of `livedb`) and enter `git --version`.

```bash
git --version
```

If you don’t have Git installed already, it will prompt you to install it.

A software update **popup window** will appear that asks: *`The xcode-select command requires the command line developer tools. Would you like to install the tools now?`* choose to confirm this by clicking **Install**, then agree to the Terms of Service.

The installer goes away on its own when complete, and you can then confirm everything is working by checking the Git version running the following command:

```
$ git --version
git version 2.20.1 (Apple Git-117)
```
> **NOTE**: If the software update was not initiated automatically after running `git --version`, you can install **Xcode Command Line Tools** by running the command below and following the same instructions as explained above:

```bash
xcode-select --install
```


### Configuring your Git credentials

The first thing you should do when you install Git is to set your user name and email address.

> **NOTE**: Replace `fullname@trustly.com` and `FirstName LastName` in the commands below with your corporate e-mail and full name.

Run updated commands in the **terminal**:

```
git config --global user.email "fullname@trustly.com"
```
```
git config --global user.name "FirstName LastName"
```


### Checking your settings

If you want to check your configuration settings, you can use the `git config --list` command to list all the settings Git can find at that point:

```bash
$ git config --list
user.name=Alfa Omega
user.email=alfa.omega@trustly.com
...
```

## Setting up a repository

> **What is a Git repository?**
> A Git repository is a virtual storage of your project. It allows you to save versions of your code, which you can access when needed.

Initiate Git repository in new directory and set active by running following command in the **terminal**:
> **NOTE**: To create a new repository, you'll use the `git init` command. Executing this command will create a new .git subdirectory in your current working directory.

```bash
mkdir ~/.support-sql-procedures && cd ~/.support-sql-procedures && git init
```

Now, once the Git repository is set, we can fetch and download the **Support SQL Stored Procedures** repository with `git pull` command and immediately update the local repository to match that content.
> **NOTE**: To authenticate with GitHub you need a `PERSONAL_TOKEN`. For security reasons, it was not published in the instructions. You can obtain it by asking @lukaszhanusik or @benjamin on Slack

```bash
git pull https://$PERSONAL_TOKEN@github.com/lukaszhanusik/support-sql-procedures.git
```
Output should look similar to this if your directory is up to date, or will show multiple changes that have happened since your last update.

```
$ git pull [..]support-sql-procedures.git
On branch master
nothing to commit, working tree clean
Already up to date.
```

## Verifying a repository path

In the **terminal**, run the command below to check if the repository has been created locally:

```bash
ls -lrt ~/.support-sql-procedures
```
```
$ ls -lrt ~/.support-sql-procedures
total 72
drwxr-xr-x   5 lukaszhanusik  staff   160 Jul  5 12:46 functions
-rw-r--r--   1 lukaszhanusik  staff   845 Jul  5 12:46 help.sql
-rw-r--r--   1 lukaszhanusik  staff   350 Jul  5 12:46 import_functions.psql
-rw-r--r--   1 lukaszhanusik  staff   338 Jul  5 12:46 import_views.psql
-rw-r--r--   1 lukaszhanusik  staff   563 Jul  5 12:46 set_aliases.psql
drwxr-xr-x   5 lukaszhanusik  staff   160 Jul  5 12:46 tables
drwxr-xr-x   6 lukaszhanusik  staff   192 Jul  5 12:46 temp
-rwxr-xr-x   1 lukaszhanusik  staff   346 Jul  5 12:46 update.sh
drwxr-xr-x   3 lukaszhanusik  staff    96 Jul  5 12:46 views
-rwxr-xr-x   1 lukaszhanusik  staff  1421 Jul  5 15:17 install.sh
-rw-r--r--   1 lukaszhanusik  staff  3307 Jul  5 16:30 README.md
drwxr-xr-x  25 lukaszhanusik  staff   800 Jul  5 16:30 procedures
-rw-r--r--   1 lukaszhanusik  staff   993 Jul  5 18:34 init.psql
-rw-r--r--   1 lukaszhanusik  staff    98 Jul  5 18:34 update.psql
```

## Configuring a database client

In the **terminal**, run the commands below to configure database client and alias:
> **NOTE**: To facilitate configuration, instructions on how to setup the configuration files were compiled into the `./install.sh` script. It will create or add new lines into existing files: `~/.psqlrc` `~/.bash_profile`

```bash
cd ~/.support-sql-procedures && ./install.sh
```

### Restart terminal

To apply the changes, **restart the terminal**. Start new window and login to the database as per usual:

```bash
livedb
```

# Updating the repository

Whenever the library has been updated, new procedures have been added, or existing functions adjusted, we need to update the repository manually.

### Update from **livedb**

While being logged to the database, you can update the repository with `:git_update` command.
> **NOTE**: `:git_update` is not a Git command. It is defined only to work with this repository and to make repository updates as seamless as possible.

```bash
gluepay=> :git_update
```
```status
gluepay=> :git_update
On branch master
nothing to commit, working tree clean
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (1/1), done.
remote: Total 4 (delta 3), reused 4 (delta 3), pack-reused 0
Unpacking objects: 100% (4/4), done.
From https://github.com/lukaszhanusik/support-sql-procedures
 * branch            HEAD       -> FETCH_HEAD
Updating 87f05db..4fa7158
Fast-forward
 init.psql        | 1 +
 set_aliases.psql | 5 -----
 2 files changed, 1 insertion(+), 5 deletions(-)
```


### Update from **terminal**

Quit database and the **terminal** windows. Start new **terminal** and run the command below to update the repository to the newest available version:

```bash
updatesql
```
```status
$ updatesql
On branch master
nothing to commit, working tree clean
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (1/1), done.
remote: Total 4 (delta 3), reused 4 (delta 3), pack-reused 0
Unpacking objects: 100% (4/4), done.
From https://github.com/lukaszhanusik/support-sql-procedures
 * branch            HEAD       -> FETCH_HEAD
Updating 87f05db..4fa7158
Fast-forward
 init.psql        | 1 +
 set_aliases.psql | 5 -----
 2 files changed, 1 insertion(+), 5 deletions(-)
```

You can login to the database as per usual:

```bash
livedb
```

### Using Google Drive for Access Log**

Install `Google Drive File Stream` and follow the instructions to initialise sync through your work email account.
