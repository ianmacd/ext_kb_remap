# **External Keyboard Remapper**

## Description

This experimental Magisk module allows the user to remap the keys of an
external keyboard.

Currently, only swapping of the `Backspace` and `Delete` keys is supported.

Please connect your keyboard before attempting to install this module. The
module will then endeavour to determine the type of keyboard in use and the
path to the associated configuration file.

To restore the default keyboard behaviour, simply deactivate or uninstall the
module and reboot.

## Troubleshooting

If installation fails, make sure your device is connected and try again.

If you are unable to get the module to work, please send details of your
device together with the contents of `/proc/bus/input/devices` to the module
developer.

## Changelog

2019-04-17: v1.0

- Initial release. Swaps `Backspace` and `Delete` keys.
