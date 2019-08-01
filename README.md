# ThinkFan
Fan control program for ThinkPad laptops.

Fan speed control is implemented as a Bash script.<br />
Program has been designed for running in command-line interface.<br />
Application runs only on Linux operating system.<br />
Only ThinkPad laptops are fully supported.

## Features

* Temperature display.
* Fan information display.
* Fan speed control.
* Fan timeout.

## Dependencies

* It is recommended to have `lm-sensors` package installed.
* Linux kernel with `thinkpad-acpi` support is required.

## Setup

* Open file `/etc/modprobe.d/thinkpad_acpi.conf` as a root.
* Add this content: `options thinkpad_acpi fan_control=1`.
* Save changes and reboot computer.
* Run program.
