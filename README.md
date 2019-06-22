# Support SQL Stored Procedures

## Install Git

1. Install Git by downloading the latest version of Git from the direct [macOS latest link](https://git-scm.com/download/mac)

2. Open the **dmg** file, then **Control/Right** click the **git.pkg** file to install

3. When Git is installed, check the version in the **Terminal**

```
git --version
```

## Set up your Git configuration

1. Configure your Git credentials in the **Terminal**

```
git config --global user.email "YOUR_TRUSTLY_EMAIL@trustly.com"
```
```
git config --global user.name "YOUR_FIRSTNAME_LASTNAME"
```

## Install repository

1. Initiate Git repository in the **Terminal**

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

## Set up your LiveDB client

1. Configure LiveDB client and link with the repository
