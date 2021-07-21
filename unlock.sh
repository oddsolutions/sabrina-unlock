#!/bin/bash

BLDRED="\033[1m""\033[31m"
RST="\033[0m"

echo -e "${BLDRED}"
echo -e "---------------------------------------"
echo -e "This script will attempt to unlock your ChromeCast with Google TV (sabrina)."
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

echo -e "\e[36m"
echo -e "---------------------------------------"
echo "Please plug unplug your CCWGTV from HDMI/USB. Please also have a USB-A to USB-C cable ready and attached to your host machine."
echo "This exploit may take a few tries to succeed, you will be walked through retying it if necessary."
echo -e "---------------------------------------"
echo -e "${RST}"

until [ "$success_status" == "yes" ]
do
echo -e "\e[36m"
echo -e "---------------------------------------"
echo "Now, hold the button on the rear of the device down while plugging the USB-C cable into the device. You should see 'Product: GX-CHIP' in your 'dmesg' upon connection."
echo -e "---------------------------------------"
echo -e "${RST}"

read -n 1 -r -s -p $'Press enter to continue...\n'

DIR=$(dirname "$(realpath "$0")")
sudo "$DIR/bin/amlogic-usbdl" "$DIR/bootloader/sabrina.bl2.noSB.noARB.img"
sudo "$DIR/bin/update" bl2_boot "$DIR/bootloader/sabrina.bootloader.bin"

echo -e "\e[36m"
echo -e "---------------------------------------"
echo "Now, unplug the device and re-plug it in. If it boots to the OS, the exploit failed. If it boots to a screen that says 'fastbootd', the exploit likely succeded."
echo -e "---------------------------------------"
echo -e "${RST}"

read -r -p "Did the device boot to 'fastbootd'?"$'\n' success_status

done

echo -e "\e[32m"
echo -e "---------------------------------------"
fastboot getvar unlocked
echo "If the above returned 'unlocked: yes', congratulations, your CCWGTV is now bootloader unlocked. Do not OTA the stock firmware! It will mitigate the underlying vulnerabillity used by this exploit and make recovery much harder."
echo "If it did not return 'yes', please contact one of the authors of this exploit with details, as your setup/device configuration is an outlier."
echo -e "---------------------------------------"
echo -e "${RST}"

exit
