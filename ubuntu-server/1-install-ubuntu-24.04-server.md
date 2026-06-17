
> **Note:** This tutorial assumes that the machine has internet access.

---

**Choose `Try or Install Ubuntu Server`:**

> Press `Enter` to get in faster.

![](assets/0-installation-boot.png)

---

**Choose `English`:**

![](assets/1-choose-english.png)

---

**Choose `Done`:**

![](assets/2-choose-done.png)

---

**Select `Ubuntu Server` and `Search for third-party drivers` then `done`:**

> `SSH` is installed but not enabled by default.

> Enable `ssh` when you finish the installation process.

![](assets/3-check-ubuntu-server-and-seach-for-third-party-drivers-then-done.png)

---

**Choose `Done`:**

> `DHCP` will give you an automatic IP.

> You can set static IP.

![](assets/4-choose-done.png)

---

**Choose `Done`:**

> We don't have a proxy so skip by leaving empty then choose `Done`:

![](assets/5-choose-done.png)

---

**Choose `Done`:**

> Unless you have a specific mirror leave as is and choose `Done`.

![](assets/6-choose-done.png)

---

**Choose `Done`:** 

> Make sure `Set up this disk as in LVM group` is selected(default).

> Unless you want a custom partitioning select `Done`.

> Note: by default not all of the available space is occupied by the LVM disk but you can expand it later after installation.

![](assets/7-choose-done.png)

---

**(Option_1)Choose `Done`:** If you are gonna expand the `/` later.

![](assets/8-choose-done.png)

**(Option_2)Expand `/` to use all available space:**

**Unmount `/`:**

![](assets/unmount-root-mount-point.png)

**Select `ubuntu-lv` -> Press `Enter` -> Select `Edit` -> Press `Enter`:**

![](assets/select-ubuntu-lvm-edit.png)

**Select `Size` then type desired size:** Max size in this case.

> **Note:** If you type a bigger value than available space it will still give it max available space.

![](assets/type-max-value.png)

**Select Mount -> Press `Enter` -> Select `/` -> Press `Enter`:**

![](assets/select-root.png)

**Select `Save` -> Press `Enter`:**

![](assets/select-save.png)


---

**Choose `Continue`:**

![](assets/9-choose-continue.png)

---

**Enter your `username`, `servername` <-> `hostname` and `password` then `Done`:**

![](assets/10-enter-credentials-then-done.png)

---

**Select `Skip for now` then `Continue`:**

![](assets/11-choose-skip-then-continue.png)

---

**Select `Install OpenSSH server` then `Done`:**

![](assets/12-choose-install-openssh-server-then-done.png)

---

**Choose `Continue`:**

> No drivers to install.

![](assets/13-choose-continue.png)

---

**Choose `Done`:**

> Select the package you want to install if you want.

![](assets/14-choose-done.png)

---

**Wait till the `Orange Bar`  at top says `Installation Complete!`:**

![](assets/15-installing.png)
![](assets/16-installion-complete.png)

---

**Choose `Reboot Now`:**

![](assets/17-choose-reboot-now.png)

---

**Press `Enter`:**

> Don't Forget To Remove The CD Installation Media After Your Are Done.

> Some hypervisors automatically remove it.

![](assets/18-press-enter.png)

---

**Enter you `username` then `password`:**

> You set during the installation process.

![](assets/19-enter-your-user-and-password.png)

---

**Login Success:**

![](assets/20-login-success.png)

