#Netdata Installation

1. [Prepare your system](#1-prepare-your-system)

  Install the required packages on your system.

2. [Install netdata](#2-install-netdata)

  Download and install netdata. You can also update it the same way.
  
3. [Extend overview page](#3-extend-overview-page)

  Add netdata instance to overview page hostet on cob4-x-b1

### 1. Prepare your system

Try our experimental automatic requirements installer (no need to be root). This will try to find the packages that should be installed on your system to build and run netdata. It supports most major Linux distributions released after 2010:

- **Arch** Linux and its derivatives
- **Gentoo** Linux and its derivatives
- **Debian** Linux and its derivatives (including **Ubuntu**, **Mint**)
- **Fedora** and its derivatives (including **Red Hat Enterprise Linux**, **CentOS**)
- **SuSe** Linux and its derivatives (including **openSuSe**)

Install all the required packages for **monitoring everything netdata can monitor**:

```sh
curl -Ss 'https://raw.githubusercontent.com/firehol/netdata-demo-site/master/install-required-packages.sh' >/tmp/kickstart.sh && bash /tmp/kickstart.sh netdata-all
```

### 2. Install netdata

Do this to install and run netdata:

```sh

# download it - the directory 'netdata' will be created
# do this on the robot account
cd ~/git
git clone https://github.com/firehol/netdata.git --depth=1
cd netdata

# build it, install it, start it
sudo ./netdata-installer.sh

```

### 3. Extend overview page

Log into cob4-x-b1 and edit/add the overview page

```sh

ssh robot@cob4-x-b1
cd /usr/share/netdata/web
vim cob-pcs.html

```

Add/Modify/Remove an block responsible for one pc

The original `cob-pcs.html` can be found here:
