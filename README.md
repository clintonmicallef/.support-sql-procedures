# SupportSQL

## Install Git

1. Install Git by downloading the latest version of Git from the direct [macOS latest link](https://git-scm.com/download/mac)

2. Open the **dmg** file, then **Control/Right** click the **git.pkg** file to install

3. When Git is installed, check the version in the **Terminal**

```
git --version
```

## Set up your Git configuration

1. Set your Git with Trustly's credentials in the **Terminal**

```
git config --global user.email "email@trustly.com"
```
```
git config --global user.name "Firstname Lastname"
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
