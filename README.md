# Support SQL Stored Procedures

Version available externally from [GitHub Gist](https://gist.github.com/lukaszhanusik/934accefc993d7d3d2bf04190ccf5087)

## Install Git

The easiest way to install **Git** is to install the **Xcode Command Line Tools** which comes with Git among other things.  You can do this simply by trying to run the git command from the Terminal.

Open a new clear **Terminal** on your Mac. Type the following command into your Terminal.

```
git --version
```

If you don’t have git installed already, it will prompt you to install it.

A software update **popup window** will appear that asks: *`The xcode-select command requires the command line developer tools. Would you like to install the tools now?`* choose to confirm this by clicking **Install**, then agree to the Terms of Service.

The installer goes away on its own when complete, and you can then confirm everything is working by checking the Git version running the following command:

```
git --version
>> git version 2.20.1 (Apple Git-117)
```

If the software update was not initiated automatically after running `git --version`, you can install **Xcode Command Line Tools** by running the command below in the **Terminal**:

```
xcode-select --install
```


## Configure your Git credentials

The first thing you should do when you install Git is to set your user name and email address.

Replace `YOUR_TRUSTLY_EMAIL` and `YOUR_FIRSTNAME YOUR_LASTNAME` in the commands below with your corporate e-mail and full name, and run them in the **Terminal**:

```
git config --global user.email "YOUR_TRUSTLY_EMAIL@trustly.com"
```
```
git config --global user.name "YOUR_FIRSTNAME YOUR_LASTNAME"
```


## Checking your settings

If you want to check your configuration settings, you can use the `git config --list` command to list all the settings Git can find at that point:

```
$ git config --list
user.name=Alfa Omega
user.email=alfa.omega@trustly.com
...
```

## Sync repository

Initiate new Git repository by running following commands in the **Terminal**:
> **WARNING**: To continue, you first need the `PERSONAL_TOKEN`. Ask Lukasz on Slack

```
mkdir ~/.support-sql-procedures
```
```
cd ~/.support-sql-procedures
```
```
git init
```
```
git pull https://d07c8b342826921a82212137a34b170493aa34e8@github.com/lukaszhanusik/support-sql-procedures.git
```


## Verify repository

In the **Terminal**, run the command below to check if the repository has been created locally:

```
ls -lrt ~/.support-sql-procedures
```

## Configure database client and set aliases

In the **Terminal**, run the commands below to configure database client and alias:

```
cd ~/.support-sql-procedures
```
```
./install.sh
```

## Restart terminal

Quit the **Terminal** windows to reset the settings. Start new window and login to the database as per usual:

```
livedb
```

# Update the repository

Whenever the library has been updated, new procedures have been added, or existing functions adjusted, we need to update the repository manually.
In order to do so,  please follow the command below:

Quit the database and the **Terminal** windows. Start new **Terminal**, run the command below to update the repository to the newest available version:

```
updatesql
```

You can login to the database as per usual:

```
livedb
```
