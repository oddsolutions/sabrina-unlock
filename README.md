# sabrina-unlock: Bootloader unlock for the Chromecast with Google TV

An exploit chain intended to allow one to run a custom OS/unsigned code on the Chromecast with Google TV (CCwGTV).

This uses [a bootROM bug in the SoC](https://fredericb.info/2021/02/amlogic-usbdl-unsigned-code-loader-for-amlogic-bootrom.html) by security researcher Frederic Basse (frederic).

Frederic also did a great amount of work to temporarily boot a custom OS from USB [here](https://github.com/frederic/sabrina-custom-os). 

Security researchers Jan Altensen (Stricted) and Nolen Johnson (npjohnson) took the vulnerability and provided tools and customized a u-boot image to take advantage of the provided secure-execution environment to fully bootloader unlock the device.

# Standard Disclaimer

You are solely responsible for any potential damage(s) caused to your device by this exploit.

# Requirements

- Chromecast With Google TV (sabrina) without USB password mitigation<sup>1</sup>
- Either a USB A to C, or a C to C cable
- A PC running some flavor of 64-bit GNU Linux
- `libusb-dev` installed

<sup>1</sup>: The USB password mitigation has been enabled on units manufactured in December 2020 and after. For units manufactured before, the mitigation was enabled by software update in February 2021. To discern this, look at the `MFP` date on the bar-code sticker on the bottom of your device's box. If you've powered it on and OTA'd, your firmware version needs to be below the February 2021 patch level.
It's not possible to disable/change the password since it's burnt into the chip (efuses).

# FAQ

Does unlocking the bootloader void my warranty on this device?

- Probably, assume so. Or just flash stock and lock your bootloader before RMA. The exploit itself leaves no traces.

Does unlocking the bootloader break DRM in any way?

- Nope, just like unlocking a Pixel device officially.

Can I OTA afterwards?

- NO - It will relock your bootloader, and if you've made any modifications, brick you pretty hard. If you manage to do this, re-running the exploit won't be possible either, as OTA's both relock the bootloader and set a burn-mode password.

Can I use stock?

- Yes, but you'd need to remove the `SetupWraith` application, or block Google's OTA servers via your router's DNS, as it will forcibly OTA you to a newer build during setup.

Can I go back to stock after installing custom OS's?

- Yeah, totally, here's a "[Factory Image](https://drive.google.com/file/d/1FbbXk5l4liDAyCwZhxQ8k3vQkJmYLPAi/view?usp=sharing)" I made in the style of Pixel Factory Images.  The patch level of this build is `2020-06-05`.

Can I relock the bootloader?

- If you flashed the factory image above, sure, but you run the risk of not being able to unlock again.

I've run the exploit 10 times and it isn't working yet!

- Swap USB ports/cables, and keep trying, for some people it takes only one attempt, for others it takes several attempts.

# Content
- /bin/: prebuilt set of required tools
  - [amlogic-usbdl](https://github.com/frederic/amlogic-usbdl): Tool to exploit bootROM bug to gain arbitrary code execution
  - [update](https://github.com/khadas/utils/blob/master/aml-flash-tool/tools/linux-x86/update): Client for the USB Burning protocol implemented in Amlogic bootloaders
- /bootloader/: prebuilt bootloader image to upload via USB
  - sabrina.bl2.noSB.noARB.img: BL2 customized to remove Secure Boot check on BL33 and anti-rollback check
  - sabrina.bootloader.bin: bootloaders (BL3x, DDR, etc...) repacked with our customized `sabrina.bl2.noSB.noARB.img` and `u-boot.bin`
  - sabrina.bootloader.factory.2020-07-13.img: bootloaders (BL3x, DDR, etc.) 
  - u-boot.bin: u-boot image built from this [repo](https://github.com/npjohnson/sabrina-unlock) 
- /scripts/: Scripts used to create the images in this repo
- /unlock.sh: Bash script to bootloader unlock CCwGTV devices

# Guide
1. Unplug the CCwGTV from everything
2. Clone/Download this repo locally, and change your shell's directory to it & ensure you `libusb-dev` installed.
3. Hold the button location on the rear of the CCwGTV case, and plug the CCwGTV into your PC via USB

The host should see a new USB device connection in `dmesg` like this one:
```text
[10504.840173] usb 1-4.3.1: new high-speed USB device number 16 using xhci_hcd
[10504.979469] usb 1-4.3.1: New USB device found, idVendor=1b8e, idProduct=c003, bcdDevice= 0.20
[10504.979495] usb 1-4.3.1: New USB device strings: Mfr=1, Product=2, SerialNumber=0
[10504.979514] usb 1-4.3.1: Product: GX-CHIP
[10504.979525] usb 1-4.3.1: Manufacturer: Amlogic
```
4. Release the button once this device has been detected by host computer.
5. Execute script **unlock&#46;sh** to load and follow the instructions it provides.

# Notices
This exploit chain modifies the content of the `env` partition to unlock the bootloader. Therefore, it would be ill advised to do any of the following:
- Modify contents of the `env` partition
- Don't OTA! Each OTA relocks the device's bootloader upon install. Additionally, the February update enforces a password to interact with Amlogic's burn-mode, which effectively mitigates this exploit, as we can't interact with the device while it's in burn-mode.

# Explanation
When the CCwGTV launched, a lot of us in the Android community were excited to see a proper successor to the Asus Nexus Player. A new Android TV to develop on!

Or not. When the CCwGTV launched, no kernel/modules/u-boot source was provided, and the bootloader was intentionally made non-unlockable.

Inquiring with Google ultimately led to the legally required GPL license releases of kernel/modules/u-boot source code.

Late last year Frederic found a [a bootROM bug](https://fredericb.info/2021/02/amlogic-usbdl-unsigned-code-loader-for-amlogic-bootrom.html) that enabled booting custom BL2/BL33 images on Amlogic S905* series chipsets.

He used it to temporarily boot Ubuntu on the device as a proof-of-concept, however, upon reboot, the device would boot back into its stock OS, and any attempts to modify the OS from the live custom environment would result in Android Verified Boot locking you out of the system.

Earlier this month, Jan and I found Frederic's work and began to theorize methods to permanently unlock the device using the access provided by the existing exploit.

After procuring several vulnerable devices from eBay by looking at the `MFP` date printed on the barcode located on the bottom of the device's box, we set to work.

The first hurdle to overcome is that all the CCwGTV's bootloader images are encrypted with an AES key and IV. To statically analyze these, we'd need that key. The easiest way to do this is to dump the memory on the device when it's in the earliest possible execution stage. Conveniently, as mentioned above, we have easy access to burn-mode, which is one of the earliest/most privileged execution contexts.

First, we dumped the device's memory while in burn-mode using the payload Frederic provides [here](https://github.com/frederic/amlogic-usbdl/blob/main/payloads/memdump_over_usb.c). We then got in contact with Frederic, who gave us the pointer that the AES key used to encrypt the bootloader lies at `0xFFFE0020`. By changing the [BOOTROM_ADDR](https://github.com/frederic/amlogic-usbdl/blob/cf66e63fbcef81163954acb4f4aef1a7246ec8e7/payloads/memdump_over_usb.c#L8) variable to the address we were given, we were able to dump the AES key in question by reading out the first 48 bytes of the dump using `hexdump`, of which the first 32 bytes were the key, and last 16 bytes were the IV.

From there, we used Frederic’s scripts [here](https://github.com/frederic/sabrina-custom-os/tree/main/scripts) in combination with the AES key we dumped to extract/decrypt sabrina's existing u-boot image.

We can verify this is the correct AES key/IV combo by running `strings` on the output u-boot image and parsing for valid strings we'd expect in u-boot, like the build string, and sure enough there it was `U-Boot 2015.01-g77f62c30a0 (Jul 13 2020 - 08:25:23)`.

Awesome, now we just need to craft a u-boot image that unlocks the device... which while you may think would be one of the hardest parts, u-boot runs in EL3, which is a highly trusted context, meaning we can arbitrarily read/write most things.

Google released the u-boot source-code for the latest CCwGTV build [here](https://drive.google.com/drive/u/0/folders/1ovzrq6uadjeUuA4GmGnE1vqjaUEznQYq?resourcekey=0-0Ck8UYZ7NIHJLdsK7WO4ZA), and it served as an invaluable reference to analyze how bootloader locking on these devices is handled.

Amlogic handles most of their persistent u-boot and general environment variables by storing them in a partition called `env`. Initially, we thought we'd have to modify the variable responsible for determining `is_unlockable`, but quickly it became apparent that simply writing directly to the `lock` variable was the most effective way to attain our goal.

To figure out what that should be, we can look at the following [line of code](https://android.googlesource.com/platform/external/u-boot/+/31fc67387a6d78371f0e8e20fe9cba76ad6357b2/drivers/usb/gadget/f_fastboot.c#1310):
```
sprintf(lock_d, "%d%d%d0%d%d%d0", info->version_major, info->version_minor, info->unlock_ability, info->lock_state, info->lock_critical_state, info->lock_bootloader);
```
Translating this, the digits of this variable correspond to `<version_major><version_minor><unlock_ability>0<lock_state><lock_critical_state><lock_bootloader>0`, which handles rollback version values, lock state, and unlock ability.

This data is all fed into [this struct](https://github.com/npjohnson/android_external_u-boot/blob/d06eb014d79649241c3018df114234fa52efb43b/include/emmc_partitions.h#L238):
```
typedef struct LockData {
	uint8_t version_major;
	uint8_t version_minor;
	uint8_t unlock_ability;
	/* Padding to eight bytes. */
	uint8_t reserved1;
	/* 0: unlock    1: lock*/
	uint8_t lock_state;
	/* 0: unlock    1: lock*/
	uint8_t lock_critical_state;
	/* 0: enable bootloader version rollback 1: prevent bootloader version rollback*/
	uint8_t lock_bootloader;
	uint8_t reserved2[1];
} LockData_t;
```

Given this, simply inserting the following code block into `common/main.c` within u-boot source before `run_preboot_environment_command` which sets all these variables would (in theory) unlock the device:
```
run_command("mmc dev 1; setenv lock 10100000; save; reboot fastboot", 0);
```
Translating this `mmc dev 1` just puts the eMMC module in a state that u-boot can write to it, `setenv lock 10100000` directly changes `lock` status from `10001110`, then `save` simply saves the environment. `reboot fastboot` isn't necessary strictly, but it is the easiest way to have the user confirm if they're unlocked.

We rolled our own u-boot with this integrated:
```
export CROSS_COMPILE=/home/$redacted/bin/toolchains/gcc-linaro-aarch64-none-elf/bin/aarch64-none-elf-
export CROSS_COMPILE_T32=/home/$redacted/bin/toolchains/gcc-linaro-arm-none-eabi/bin/arm-none-eabi-
make sm1_sabrina_v1_defconfig
make
```
We then used Frederic's `repack_bootloader.sh` to repack our customized u-boot and his customized BL2 image that ignores BL33 (u-boot) signature and nulls out the anti-rollback check.

Unfortunately, as things often are, this was not as easy as it would seem. The new image didn't boot at all.

Turns out, we needed to follow Frederic's example, and first enable [UART console](https://github.com/npjohnson/android_external_u-boot/commit/845ca51750f55f202f5c97288a1197cfd8d133d1) and configure it to debug the issue further. The awesome people over at [Exploiteers](https://www.exploitee.rs/) already did the leg work identifying RX/TX pads on the board, and the awesome PCBite tools from the people over at SensePeek made it easy to get UART logs up and printing.

![Here's a photo of my setup.](https://i.imgur.com/WI5sS0W.jpeg)

For convenience's sake, we also removed the `0` second boot-delay and flags that [disable update mode](https://github.com/npjohnson/android_external_u-boot/commit/1a9aba0693614c3bb1a0420c529c000645f6427d), and removed a few other small restrictions to debug the issue.

The issue turned out to be that we were getting tossed into burn mode - which was quickly discovered to be easily bypassed by disabling the config that [forces it](https://github.com/G12-Development/android_external_u-boot/commit/e398d184d4f4db422d83bf5e44fbe96b30b9f18c)!

With this in place, it was as simple as re-building u-boot, repacking the bootloader image, and then re-running the exploit to upload the custom bootloader.

UART logs then showed that our u-boot was not only executed, but `env` modified just as we intended, saved to the block device, and then the device (tried) to reboot to `fastbootd` mode, however, likely due to lingering effects of the exploit, it booted back to burn mode. Simple unplugging the device and re-plugging it in let it fire up, detect the persistent boot-reason variable, and kicked us to `fastbootd` mode.

We then ran `fastboot getvar unlocked` to grab the lock status and... success!

```
unlocked: yes
Finished. Total time: 0.001s
```

Now, because Android isn't stupid, and at least tries to maintain user-data security, attempting to reboot will dump us into Android Recovery saying the "System is corrupt and can't boot", simply using the button on the device, and short pressing to highlight "Factory Data Reset", then long pressing it to select, and confirming your selection, then rebooting will remedy the situation, and your device will boot into the stock OS, freshly unlocked.

This was an extremely fun process and goes to show that releasing your vulnerability research can lead to even cooler discoveries!

# Demo
Demo video: [Chromecast with Google TV Bootloader Unlock](https://youtu.be/HWa9mraQVSo)

# Credits
- Nolen Johnson (npjohnson): The writeup, helping debug/develop/theorize the unlock method
- Jan Altensen (Stricted): The initial concept, u-boot side unlock implementation, debugging/developing the unlock method, and being a wealth of information when it comes to Amlogic devices 
- Frederic Basse (frederic): The initial exploit and the AES key tip

# Special Thanks
- Ryan Grachek (oscardagrach): Being an awesome mentor, teaching me a fair chunk of what I know about hardware security, and being a massive wealth of knowledge about most random things.
- Chris Dibona: Being an awesome advocate of OSS software and helping ensure that we got all the source-code pertinent to the device.
- Pierre-Hugues Husson (phh): For pointing me down the Amlogic road to begin with by letting me know Google had decided to make the ADT-3 bootloader unlockable.

# Contribute to FOSS development on this device
- U-Boot: [sabrina-uboot](https://github.com/npjohnson/android_external_u-boot)
- Android: [android_device_google_sabrina](https://github.com/LineageOS/android_device_google_sabrina)
- GNU/Linux: [sabrina-linux](https://github.com/frederic/sabrina-linux)

