# RTL FPGA Projects

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

These project are based on the Digilent [ARTY Z7](https://reference.digilentinc.com/reference/programmable-logic/arty-z7/start) board.

![digilent](https://reference.digilentinc.com/_media/reference/programmable-logic/arty-z7/arty-z7_-_obl_-_600.png)


## Vivado: Installing Digilent Board Files

Download the [archive](https://github.com/Digilent/vivado-boards/archive/master.zip?_ga=2.97053599.1009087387.1591531709-2003481732.1591531709) of the vivado-boards Github repository and extract it to:

```
/opt/Xilinx/Vivado/2019.2/data/boards/board_files
```

Additional drivers can be found in

```
/opt/Xilinx/Vivado/2019.2/data/xicom/cable_drivers/lin64/install_script/install_drivers
```

## PetaLinux

### Installation Environment Requirements

The installer need this package

Ubuntu
```
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install zlib1g:i386
```

Missing in CentOS8
```
sudo yum install zlib-devel
sudo yum install xterm
sudo yum install SDL-devel
sudo yum install glib2-devel
sudo yum install screen
sudo yum install python3-jinja2
sudo yum install python3-GitPython
```

All others
```
sudo yum install iproute
sudo yum install gcc
sudo yum install g++
sudo yum install netstat
sudo yum install ncurses-devel
sudo yum install openssl-devel
sudo yum install flex
sudo yum install bison
sudo yum install libselinux
sudo yum install autoconf
sudo yum install libtool
sudo yum install texinfo
sudo yum install glibc-devel
sudo yum install glibc.i686
sudo yum install glibc.x86_64
sudo yum install automake
sudo yum install pax ?
sudo yum install libstdc++.x86_64
sudo yum install libstdc++.i686
sudo yum install patch
sudo yum install diffutils
sudo yum install cpp
sudo yum install perl-Data-Dumper
sudo yum install perl-Text-ParseWords
sudo yum install perl-Thread-Queue
sudo yum install xz
```

### Design Flow Overview
Hardware platform creation (for custom hardware only)Vivado® design toolsCreate a PetaLinux project
petalinux-create -t project
Initialize a PetaLinux project (for custom hardware only)
petalinux-config --get-hw-description
Configure system-level options
petalinux-config
Create user components
petalinux-create -t COMPONENT
Configure the Linux kernel
petalinux-config -c kernel
Configure the root filesystem
petalinux-config -c rootfs
Build the system
petalinux-build
Package for deploying the system
petalinux-package
Boot the system for testing
petalinux-boot


## This Repository Is Using pre-commit

Installing
```bash
pip3 install pre-commit
```

Enable automatic hook install when cloning repositories
```bash
git config --global init.templateDir ~/.git-template
pre-commit init-templatedir ~/.git-template
```

Install in already clones repositories
```bash
pre-commit install
```

Add hooks to
```
.pre-commit-config.yml
```
