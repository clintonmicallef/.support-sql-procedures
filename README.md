# Support SQL Stored Procedures

## Install Git

The easiest way to install **Git** is to install the **Xcode Command Line Tools** which comes with Git among other things.  You can do this simply by trying to run the git command from the Terminal.

1. Open a new clear **Terminal** on your Mac. Type the following command into your Terminal.

```
git --version
```

2. If you don’t have git installed already, it will prompt you to install it.

3. A software update **popup window** will appear that asks: “__The xcode-select command requires the command line developer tools. Would you like to install the tools now?__” choose to confirm this by clicking **Install**, then agree to the Terms of Service when requested.

4. The installer goes away on its own when complete, and you can then confirm everything is working by checking the Git version by running the following command:

```
git --version
```

Alternatively, you can install xCode CLI by running the command below in the **Terminal**:

```
xcode-select --install
```


## Configure your Git credentials

Once the Git client is installed, configure your Git profile with your real credentials. This allows to access the team resources and track changes.

1. Replace `YOUR_TRUSTLY_EMAIL` and `YOUR_FIRSTNAME_LASTNAME` in the commands below and run them in the **Terminal**:

```
git config --global user.email "YOUR_TRUSTLY_EMAIL@trustly.com"
```
```
git config --global user.name "YOUR_FIRSTNAME_LASTNAME"
```


## Sync repository

1. Initiate Git repository by running following commands in the **Terminal**:

```
mkdir ~/.trustly-support-sql
```
```
cd ~/.trustly-support-sql
```
```
git init
```
```
git pull https://0518c76da1808fe52255329f0d020aa39346b5d5@github.com/lukaszhanusik/SupportSQL.git
```


## Verify repository

1. In the **Terminal**, run the command below to check if the repository has been created locally:

```
ls -lrt ~/.trustly-support-sql
```
