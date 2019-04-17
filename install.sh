##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=false

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "******************************"
  ui_print "  External keyboard remapper  "
  ui_print "******************************"
}

# Copy/extract your module files into $MODPATH in on_install.

on_install() {
  # The following is the default implementation: extract $ZIPFILE/system to $MODPATH
  # Extend/change the logic to whatever you want
  ui_print "- Extracting module files"
  unzip -o "$ZIPFILE" 'system/*' -d $MODPATH >&2

  # cat /proc/bus/input/devices
  #
  # I: Bus=0005 Vendor=04e8 Product=7021 Version=001b
  # N: Name="ZAGG Keyboard"
  # P: Phys=
  # S: Sysfs=/devices/virtual/misc/uhid/0005:04E8:7021.0001/input/input10
  # U: Uniq=76:10:23:12:32:38
  # H: Handlers=leds event10
  # B: PROP=0
  # B: EV=12001b
  # B: KEY=4 0 1 0 0 0 40000000000000 0 1000302000007 ff9f387ad941d7ff febeffdfffefffff fffffffffffffffe
  # B: ABS=70000000000
  # B: MSC=10
  # B: LED=1f
  #
  # To get file name to operate on:
  #
  # sed -rne '/^I: Bus=/{N;/[Kk]eyboard/s/^.+(Vendor)=(....) (Product)=(....).+$/\1_\2_\3_\4.kl/p}'

  ui_print ""
  ui_print "- Please connect your device before installing!"
  ui_print ""
  ui_print "- This module may not work with all keyboards. It is known to"
  ui_print "- work with at least some ZAGG Bluetooth keyboards."
  ui_print ""

  mirror=/sbin/.magisk/mirror
  in_devs=/proc/bus/input/devices
  kl_dir=/system/usr/keylayout

  eval $(sed -rne '/^I: Bus=/{N;/[Kk]eyboard/s/^.+(Vendor)=(....) (Product)=(....).+Name="([^"]+).+$/kl=\1_\2_\3_\4.kl; kb="\5"/p}' $in_devs)

  if [ -z "$kl" ]; then
    ui_print "- No external keyboard found."
    ui_print "- Is your device currently connected?"
    exit 1
  elif [ ! -f $kl_dir/$kl ]; then
    ui_print "- $kb device found, but keyboard layout file $kl not found."
    exit 2
  fi

  # Remap keyboard.
  #
  # kl=/system/usr/keylayout/Vendor_04e8_Product_7021.kl
  ui_print "- $kb device found."
  ui_print "- Keyboard layout file $kl found."

  ui_print "- Modifying file..."

  mkdir -p $MODPATH$kl_dir
  cp -p $mirror$kl_dir/$kl $MODPATH$kl_dir
  old_md5=$(md5 $MODPATH$kl_dir/$kl)
  sed -i -e '/[[:blank:]]DEL$/{s/DEL/FORWARD_DEL/;n}' \
         -e '/[[:blank:]]FORWARD_DEL$/{s/FORWARD_DEL/DEL/;n}' \
	 $MODPATH$kl_dir/$kl
  new_md5=$(md5 $MODPATH$kl_dir/$kl)

  if [ $old_md5 = $new_md5 ]; then
    ui_print "- Failed to make any changes. Please contact the developer."
    exit 3
  fi

  ui_print "- Old MD5 sum: $old_md5."
  ui_print "- New MD5 sum: $new_md5."
  ui_print ""

}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

# You can add more functions to assist your custom script code

md5() {
  # Magisk's BusyBox evidently doesn't support -b switch to md5sum.
  md5sum -b "$1" | cut -d' ' -f 1
}
