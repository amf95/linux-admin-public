
# Install `openssh-server`:

**Debian, Ubuntu, Mint, ...**
```bash
apt install openssh-server
```

**Redhat, Centos, Fedora, ...**
```bash
dnf install openssh-server
```

----
# SSH Hardening:

> It's better if you use `VPN` to connect to your remote servers but in case you don't have `VPN` here are some steps to harden your `ssh` connection.

> Even if you are using `VPN` or on a local network you still must harden your `ssh` connection.

> **IMPORTANT:** Apply changes incrementally and always keep an active session open while testing to avoid locking yourself out.

> **Note:** Restart/Reload ssh daemon each time you edit something so that changes will take effect.

**Debian, Ubuntu, Mint, ...**
```bash
sudo systemctl restart ssh
```

**Redhat, Centos, Fedora, ...**
```bash
sudo systemctl restart sshd
```

---
## **A.** On Your Device:

> We will generate private and public keys for authentication instead of password authentication, private and public keys should not be shared with anyone, public key will be copied to the remote server.

> You can generate one key for all of your servers, or generate one key for each environment, or a key for each remote server.

#### 1. Generate Private and public key:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<KEY_NAME>  -C "SOME_COMMENT"
```

> `ed25519`: Algorithm used for key generation.

> `Ed25519` is better than `RSA`, if you use `RSA` use at least `4096` bits.

> `<KEY_NAME>`: location where the keys will be stored, default is in `~/.ssh/` with the name of the encryption algorithm,  **EXP** -> `~/.ssh/prod_key`, `~/.ssh/test_key`, `~/.ssh/my_key`.

> `-N "PASSWORD"`: Used to protect the private key if it was stolen, you will be asked to enter that private password each time you use that key, if you don't use that option you will be prompted to enter a password when you run the command above, leave empty and press enter if you don't want to protect it with a password.

> `SOME_COMMENT`: is added to the end of `~/.ssh/<KEY_NAME>` private file, **EXP** -> `Ahmed_Laptop`.

**EXP:**
```bash
ahmed@pc:~/.ssh$ ssh-keygen -t ed25519 -f ~/.ssh/for_test  -C "For_TEST"
Generating public/private ed25519 key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /home/ahmed/.ssh/for_test
Your public key has been saved in /home/ahmed/.ssh/for_test.pub
The key fingerprint is:
SHA256:H2JlgBlFv+xwq+McZzyONRTuQhwkvbYUMYN8vNt42oc For_TEST
The key's randomart image is:
+--[ED25519 256]--+
|     .oXO.       |
|      =o==       |
|       ..+=      |
|       .=* o     |
|       oS=B      |
|       o+Xoo     |
|        o+%.     |
|       .oXEo.    |
|       .=...     |
+----[SHA256]-----+
```

```bash
ahmed@pc:~/.ssh$ ls
for_test  for_test.pub  known_hosts
```

```bash
ahmed@pc:~/.ssh$ cat for_test.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJElbM/OCGK5Al8CljAHx7OlcjwaWZR2KfPAaXdewKqE For_TEST
```

**Modify permissions on your device:**
```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/<KEY_NAME>        # private key
chmod 644 ~/.ssh/<KEY_NAME>.pub    # public key
```

**Modify permissions on your remote server:**
```bash
chmod 600 ~/.ssh/authorized_keys
```

> Without these permissions it might not work.

#### 2. Move public key to remote server:

> You can copy the content of the `.pub` file and past it in the remote server in `~/.ssh/authorized_keys` file, if the following command doesn't work.

```bash
ssh-copy-id -i ~/.ssh/<KEY_NAME>.pub <USER>@<REMOTE_SERVER>
```

```bash
ssh-copy-id -p <PORT_NUMBER> -i ~/.ssh/<KEY_NAME>.pub <USER>@<REMOTE_SERVER>
```

> You will be prompted to enter the password of the ed25519 private key file aka: `~/.ssh/<KEY_NAME>`.

**EXP:**
```bash
ahmed@pc:~/.ssh$ ssh-copy-id -p 9999 -i ~/.ssh/for_test.pub ahmed@192.168.1.99

/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/ahmed/.ssh/for_test.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
ahmed@192.168.1.99's password: 

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh -p 9999 'ahmed@192.168.1.99'"
and check to make sure that only the key(s) you wanted were added.
```

> Make sure key authentication is enabled on the remote server in the next steps.

```bash
cat ~/.ssh/authorized_keys
```

> Now go to the `B` section to configure the remote server, specially `Enable Public key Authentication` and `Disable Password Authentication`.

---
## **B.** On The Remote Server:

> **NOTE:** The most important modifications are `PubkeyAuthentication yes`, `PermitRootLogin no`, `PasswordAuthentication no`.

| Summary                                       |
| --------------------------------------------- |
| Disable root login                            |
| Enable Public key Authentication              |
| Disable Password Authentication               |
| Disable empty passwords                       |
| Change the default port                       |
| Limit login attempts and timeout per session  |
| Allow only specific users or groups           |
| Bind to specific interfaces only              |
| Disable unused features                       |
| Restrict to modern, secure algorithms         |
| Inactive/Unresponsive clients Session Timeout |
| Enable Logging                                |
| Firewall Rules                                |
| Ban Abusing Logins                            |
| Two-Factor Authentication                     |

#### Open `/etc/ssh/sshd_config`:

```bah
vim /etc/ssh/sshd_config
```

#### Summary:

| Setting                | Value                                                       |
| ---------------------- | ----------------------------------------------------------- |
| PermitRootLogin        | no                                                          |
| PubkeyAuthentication   | yes                                                         |
| PasswordAuthentication | no                                                          |
| PermitEmptyPasswords   | no                                                          |
| Port                   | NUMBER -> EXP: 9797                                         |
| MaxAuthTries           | 3                                                           |
| LoginGraceTime         | 30                                                          |
| AllowUsers             | USER_NAME -> EXP: ahmed                                     |
| ListenAddress          | NIC_IP -> EXP: 192.168.1.10                                 |
| X11Forwarding          | no                                                          |
| AllowAgentForwarding   | no                                                          |
| AllowTcpForwarding     | no                                                          |
| PermitTunnel           | no                                                          |
| KexAlgorithms          | curve25519-sha256,diffie-hellman-group14-sha256             |
| Ciphers                | aes256-gcm@openssh.com,chacha20-poly1305@openssh.com        |
| MACs                   | hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com |
| HostKeyAlgorithms      | ssh-ed25519,rsa-sha2-512                                    |
| ClientAliveInterval    | 300                                                         |
| ClientAliveCountMax    | 2                                                           |
| LogLevel               | VERBOSE                                                     |
### Basics:
#### Disable root login:

```
PermitRootLogin no
```

#### Enable Public key Authentication:

```
PubkeyAuthentication yes
```

#### Disable Password Authentication:

> `publickey` is the default authentication method once you disable `PasswordAuthentication`.

```
PasswordAuthentication no
```

#### Disable empty passwords:

```
PermitEmptyPasswords no
```

#### Change the default port:

```
Port <NUMBER>
```

> Reduces automated port scanning.

> Replace `NUMBER` with any unused port above 1024.

#### Limit login attempts and timeout per session:

```
MaxAuthTries 3
LoginGraceTime 30
```

---
### Restrict Access:

#### Allow only specific users or groups:

```
AllowUsers <USER_NAME>
```

```bash
AllowGroups <GROUP_NAME>
```

> User should belonging to the group allowed.

> **IMPORTANT:** Make sure your user name is among the  `AllowUsers` -> `AllowUsers ahmed john` otherwise you will be logged out when your restart the `ssh` service.

#### Bind to specific interfaces only: 

> If server has multiple NICs.

```
ListenAddress <NIC_IP>
```

> Replace `<NIC_IP>` with the IP of the interface you are connecting to, **EXP**: `192.168.1.10`.

#### Disable unused features:

```
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitTunnel no
```

---
### Use Strong Cryptography:

#### Restrict to modern, secure algorithms:

**Add the following:**
```
KexAlgorithms curve25519-sha256,diffie-hellman-group14-sha256
Ciphers aes256-gcm@openssh.com,chacha20-poly1305@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512
```

---
### Inactive/Unresponsive clients Session Timeout:

```
ClientAliveInterval 300
ClientAliveCountMax 2
```

> `Server` sends `keep alive message`  to the `Client` each `300s`, if `2` messages where sent and no response from the client then session is terminated -> free memory and avoid open session attacks.

**Message looks something like this when you do nothing on your terminal:**
```bash
debug1: client_input_channel_req: channel 0 rtype keepalive@openssh.com reply 1
```

---
#### Enable Logging:

```
LogLevel VERBOSE
```

> Logs successful and failed auth attempts for auditing.

---
### Firewall Rules:

> Close old ports then open new ports to your SSH clients.
 
> Replace `<NEW_PORT>` with your chosen SSH port.

> **IMPORTANT:** Always open the new port **before** closing port 22, and verify your key-based login works on the new port before ending your current session.
#### UFW: Debian, Ubuntu, Mint, ...

> Assuming you have it enabled -> `ufw enable`.

```bash
ufw allow from <YOUR_IP> to any port <NEW_SSH_PORT> proto tcp comment "<COMMENT_HERE>"
```

```bash
ufw status numbered
```
####  Firewalld: Redhat, Centos, Fedora, ...

**Remove old default SSH port:**
```bash
firewall-cmd --permanent --remove-service=ssh
```

**Apply:**
```bash
firewall-cmd --reload
```

**Restrict to specific IP only:**
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<YOUR_IP>" port port="<NEW_PORT>" protocol="tcp" accept'
firewall-cmd --reload
```

**Verify:**
```bash
firewall-cmd --list-all
```

---
### Ban Abusing Logins:

> Automatically bans IPs with repeated failed logins.

#### Install `Fail2Ban`:

**Debian, Ubuntu, Mint, ...**
```bash
apt install fail2ban -y
systemctl enable --now fail2ban # Enable and Start.
```

**Redhat, Centos, Fedora, ...**
```bash
dnf install epel-release -y
dnf install fail2ban -y
systemctl enable --now fail2ban # Enable and Start.
```

**Configs:**
```bash
vim /etc/fail2ban/jail.local
```

```bash
[sshd]
enabled = true
port    = <NUMBER>
maxretry = 3
bantime  = 1h
findtime = 10m
```

> **Explanation**: If an IP fails to login 3 times on port (EXP: `<NUMBER>`=2222) within a time window of 10m ban that IP for 1h.

---
### Two-Factor Authentication:

> **IMPORTANT:** Two-Factor Authentication is sensitive to time drafts on the server and you wont be able to login with it if your server's clock is out of sync.
#### Install Google Authenticator:

**Debian, Ubuntu, Mint, ...**
```bash
apt update
apt install libpam-google-authenticator -y
```

**Redhat, Centos, Fedora, ...**
```bash
dnf install -y epel-release google-authenticator-libpam
```

#### Run `google-authenticator`:

```bash
google-authenticator
```

> All answers to questions are (yes).

> Scan the QR-code.

> Copy the `emergency scratch codes` and store them somewhere safe in case you can't use google authenticator.

> If you use one of the `emergency scratch codes` you can add it back in this file: `~/.google_authenticator`.

#### Edit The Following Files:

```bash
vim /etc/pam.d/sshd
```

**Add to the top:**
```bash
auth required pam_google_authenticator.so
```

> You can disable `google_authenticator` by commenting `auth required pam_google_authenticator.so`.

---

```bash
vim /etc/ssh/sshd_config
```

```bash
ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive
```

---
