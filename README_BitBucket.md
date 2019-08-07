### Quick config notes to work with BitBucket read-only repositories via SSH

Open new terminal window and run the command below.
It will display the public key in the terminal.

```bash
cat ~/.ssh/id_rsa.pub
```

Share this SSH public key with Lukasz or Team Leader who initiated the process and paste a clipboard in a private Slack chat. (`cmd + v`)

If an error is displayed, example: "File not found", please follow the below steps: 
1. Open a new Terminal Window
2. Enter: ```ssh-keygen``` and press ENTER
3. Type: ```/Users/[CHANGE->yourhomefolderusername]/.ssh/id_rsa
4. Enter a password (any password) and repeat when prompted

You should see a result starting with: `The key fingerprint is:`

5. Return back to: ```cat ~/.ssh/id_rsa.pub```


Your key is being manually added to the list of trusted users.
Create new directory with the repository and initiate Git.

```bash
mkdir ~/.test_bitbucket && cd ~/.test_bitbucket && git init
```

You should see your repository was initialised:
```
$ Initialized empty Git repository in /Users/lukaszhanusik/.test_bitbucket/.git/
```

You can download the repository by running:
> **NOTE** Confirm with the person on Slack your keys are already added : )

```bash
git pull git@bitbucket.org:TrustlySupport/support-sql-procedures.git
```

> **NOTE** When you connect for the first time to BitBucket, SSH prompts you to verify the authenticity of the server. It is just an added security measure to verify the server using the RSA key fingerprint. You can type **yes** and proceed. _This is a one time verification._
```
$ The authenticity of host 'bitbucket.org (18.205.93.1)' can't be established.
RSA key fingerprint is SHA256:zzXQOXS[RBEiUtuE8AikJYKwbHaxvSc0ojez9]YXaGp1A.
Are you sure you want to continue connecting (yes/no)? yes
```

BitBucket added to the list of known hosts.
Your repository is pulling the files...
Maybe you will be asked to give the password to this key. It is the same password you are using to log into the Tunnel _(first password when starting new tunnel...)_

```
$ Warning: Permanently added 'bitbucket.org,18.205.93.1' (RSA) to the list of known hosts.
$ Enter passphrase for key '/Users/lukaszhanusik/.ssh/id_rsa':
remote: Counting objects: 523, done.
remote: Compressing objects: 100% (258/258), done.
remote: Total 523 (delta 260), reused 513 (delta 254)
Receiving objects: 100% (523/523), 248.64 KiB | 553.00 KiB/s, done.
Resolving deltas: 100% (260/260), done.
From bitbucket.org:TrustlySupport/support-sql-procedures
 * branch            HEAD       -> FETCH_HEAD
 ```

**Success!**
