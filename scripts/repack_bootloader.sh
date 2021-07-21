#!/bin/sh

# repack bootloader partition with custom BL33 (u-boot.bin)
# note : AES key not provided
# this script requires to run (once) decrypt_bootloader.sh first to create file sabrina.bootloader.plain.img
DIR=$(dirname $(realpath $0))

$DIR/../bin/aml_encrypt_g12a --bl3sig --input $DIR/../bootloader/u-boot.bin --compress lz4 --output $DIR/../bootloader/sabrina.BL33.encv12  --level v3 --type bl33
IN_OFFSET=`grep --byte-offset --only-matching --text LZ4C $DIR/../bootloader/sabrina.BL33.encv12 | head -1 | cut -d: -f1`
OUT_OFFSET=`grep --byte-offset --only-matching --text LZ4C $DIR/../bootloader/sabrina.bootloader.plain.img | head -1 | cut -d: -f1`
dd if=$DIR/../bootloader/sabrina.BL33.encv12 of=$DIR/../bootloader/sabrina.bootloader.plain.img skip=$IN_OFFSET seek=$OUT_OFFSET bs=1 conv=notrunc
openssl enc -aes-256-cbc -nopad -e -K $key -iv $iv -in $DIR/../bootloader/sabrina.bootloader.plain.img -out $DIR/../bootloader/sabrina.bootloader.enc.img
dd if=$DIR/../bootloader/sabrina.bootloader.enc.img of=$DIR/../bootloader/sabrina.bootloader.bin seek=4096 bs=16 conv=notrunc
