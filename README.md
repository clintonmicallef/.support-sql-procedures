# Support SQL Stored Procedures

## Install Git with Xcode Command Line Tools

1. Launch new clear **Terminal** window.

2. Type the following command:

```
xcode-select --install
```

3. A software update **popup window** will appear that asks: “__The xcode-select command requires the command line developer tools. Would you like to install the tools now?__” choose to confirm this by clicking **Install**, then agree to the Terms of Service when requested.

4. The installer goes away on its own when complete, and you can then confirm everything is working by checking the Git version by running the following command:

```
git --version
```

## Configure your Git credentials

1. Replace `YOUR_TRUSTLY_EMAIL` and `YOUR_FIRSTNAME_LASTNAME` in the commands below and run them in the **Terminal**:

```
git config --global user.email "YOUR_TRUSTLY_EMAIL@trustly.com"
```
```
git config --global user.name "YOUR_FIRSTNAME_LASTNAME"
```

## Install repository

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

1. In the **Terminal**, run the command to check if the repository files have been downloaded:

```
ls -lrt ~/.trustly-support-sql
```
