#!/bin/bash

BLDRED="\033[1m""\033[31m"
RST="\033[0m"

echo -e "${BLDRED}"
echo -e "---------------------------------------"
echo -e "This script will attempt to repair your ChromeCast with Google TV (sabrina)."
echo -e "Proceed at your own risk, no warranty is implied/provided."
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Please type 'I Understand' and press enter to proceed"$'\n' confirm
if [ "$confirm" != "I Understand" ]
then
exit 1
else
printf "\n"
fi

command -v fastboot >/dev/null 2>&1 || { echo >&2 "fastboot is not in PATH, please ensure the SDK platform tools (https://developer.android.com/studio/releases/platform-tools) are in PATH."; exit 1; }
command -v mke2fs >/dev/null 2>&1 || { echo >&2 "mke2fs is not in PATH, please ensure the SDK platform tools (https://developer.android.com/studio/releases/platform-tools) are in PATH."; exit 1; }
ldconfig -p | grep libusb-0.1.so.4 >/dev/null 2>&1 || { echo >&2 "libusb-0.1-4 is not found, please install: libusb-dev (Debian-based) / libusb-compat (Arch-based)."; exit 1; }

echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Please plug unplug your CCWGTV from HDMI/USB. Please also have a USB-A to USB-C cable ready and attached to your host machine."
echo -e "This exploit may take a few tries to succeed, you will be walked through retying it if necessary."
echo -e "---------------------------------------"
echo -e "${RST}"

until [ "$success_status" == "yes" ] || [ "$success_status" == "Yes" ]
do
echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Now, hold the button on the rear of the device down while plugging the USB-C cable into the device. You should see 'Product: GX-CHIP' in your 'dmesg' upon connection."
echo -e "---------------------------------------"
echo -e "${RST}"

read -n 1 -r -s -p $'Press enter to continue...\n'

DIR=$(dirname "$(realpath "$0")")
sudo "$DIR/bin/amlogic-usbdl" "$DIR/bootloader/sabrina.bl2.noSB.noARB.img"
sudo "$DIR/bin/update" bl2_boot "$DIR/bootloader/sabrina.bootloader.burnmode.bin"
sleep 5s
sudo "$DIR/bin/update" bulkcmd "mmc dev 1"
sudo "$DIR/bin/update" mwrite "repair/dtb.img" mem dtb normal
sudo "$DIR/bin/update" partition _aml_dtb "repair/dtb.img"
sudo "$DIR/bin/update" partition dtbo "repair/dtbo.img"
sudo "$DIR/bin/update" partition boot "repair/boot.img"
sudo "$DIR/bin/update" partition recovery "repair/recovery.img"
sudo "$DIR/bin/update" partition vbmeta "custom-images/disabled_vbmeta.img"

echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Now, unplug the device and re-plug it in while holding the button on the rear of the device. You should see 'Product: GX-CHIP' in your 'dmesg' upon connection."
echo -e "---------------------------------------"
echo -e "${RST}"

read -n 1 -r -s -p $'Press enter to continue...\n'

sudo "$DIR/bin/amlogic-usbdl" "$DIR/bootloader/sabrina.bl2.noSB.noARB.img"
sudo "$DIR/bin/update" bl2_boot "$DIR/bootloader/sabrina.bootloader.bin"


echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Now, unplug the device and re-plug it in."
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Did the device boot to 'fastbootd'?"$'\n' success_status

done

echo -e "\e[32m"
echo -e "---------------------------------------"
fastboot getvar unlocked
echo "If the above returned 'unlocked: yes', congratulations, your CCWGTV is now bootloader unlocked and repaired."
echo "If it did not return 'yes', please contact one of the authors of this exploit with details, as your setup/device configuration is an outlier."
echo -e "---------------------------------------"
echo -e "${RST}"


echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Now, in order to prevent SetupWizard from auto-updating the device, a specific much newer factory image can to be flashed. Alternatively you can flash anything from fastbootd at this point."
echo -e "Would you like to proceed flashing the modified stock image? It will wipe userdata, and requires an internet connection."
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Please type 'Yes' and press enter to flash it, or 'No' to proceed"$'\n' factory_image
if [ "$factory_image" != "Yes" ] && [ "$factory_image" != "yes" ]
then
printf "\n"
else
wget -O sabrina-qts1.210311.036-7814738-factory.zip https://download.ods.ninja/Android/firmware/sabrina/sabrina-qts1.210311.036-7814738-factory.zip
unzip -o sabrina-qts1.210311.036-7814738-factory.zip
fastboot reboot bootloader
fastboot flash dtb sabrina-qts1.210311.036-7814738-release-keys/dt.img
fastboot flash dtbo sabrina-qts1.210311.036-7814738-release-keys/dtbo.img
fastboot reboot bootloader
fastboot flash boot sabrina-qts1.210311.036-7814738-release-keys/boot.img
fastboot flash logo sabrina-qts1.210311.036-7814738-release-keys/logo.img
fastboot flash recovery sabrina-qts1.210311.036-7814738-release-keys/recovery.img
fastboot -w
fastboot reboot fastboot
fastboot flash odm sabrina-qts1.210311.036-7814738-release-keys/odm.img
fastboot flash product sabrina-qts1.210311.036-7814738-release-keys/product.img
fastboot flash system sabrina-qts1.210311.036-7814738-release-keys/system.img
fastboot flash vendor sabrina-qts1.210311.036-7814738-release-keys/vendor.img
fastboot flash vbmeta custom-images/disabled_vbmeta.img
fi

echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Would you like to flash a Magisk patched boot image?"
echo -e "This will root your device and allow you to install the Magisk APK"
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Please type 'Yes' and press enter to flash it, or 'No' to proceed"$'\n' magisk_boot
if [ "$magisk_boot" != "Yes" ] && [ "$success_status" != "yes" ]
then
printf "\n"
else
fastboot flash boot custom-images/magisk_boot.img
fi

echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "Would you like to flash LineageOS Recovery?"
echo -e "It is a custom recovery that allows you to flash ROMs, zip files, etc."
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Please type 'Yes' and press enter to flash it, or 'No' to proceed"$'\n' custom_recovery
if [ "$custom_recovery" != "Yes" ] && [ "$success_status" != "yes" ]
then
printf "\n"
else
fastboot flash recovery custom-images/lineage_recovery.img
fastboot flash dtbo custom-images/lineage_dtbo.img
fastboot reboot bootloader
fastboot flash dtb custom-images/lineage_dtb.img
fastboot boot custom-images/lineage_recovery.img
fi

if [ "$factory_image" != "Yes" ] && [ "$factory_image" != "yes" ]
then
echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "All done! Your device is in fastbootd, enjoy!!"
echo -e "---------------------------------------"
echo -e "${RST}"
else
echo -e "\e[36m"
echo -e "---------------------------------------"
echo -e "All done! Your device will reboot to the stock OS shortly. You CAN NOT update the device, it will either fail or brick your device. Beyond that, enjoy!"
echo -e "---------------------------------------"
echo -e "${RST}"
fastboot reboot
fi

rm -Rf sabrina-qts1.210311.036-7814738-release-keys*

exit
