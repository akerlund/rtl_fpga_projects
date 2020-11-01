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