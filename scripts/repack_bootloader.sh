#!/bin/sh

# repack bootloader partition with custom BL33 (u-boot.bin)
# note : AES key not provided
# this script requires to run (once) decrypt_bootloader.sh first to create file sabrina.bootloader.plain.img
DIR=$(dirname $(realpath $0))

$DIR/../bin/aml_encrypt_g12a --bl3sig --input $DIR/../bootloader/u-boot.bin --compress lz4 --output $DIR/../bootloader/sabrina.BL33.encv12  --level v3 --type bl33
IN_OFFSET=`grep --byte-offset --only-matching --text LZ4C $DIR/../bootloader/sabrina.BL33.encv12 | head -1 | cut -d: -f1`
OUT_OFFSET=`grep --byte-offset --only-matching --text LZ4C $DIR/../bootloader/sabrina.bootloader.plain.img | head -1 | cut -d: -f1`
dd if=$DIR/../bootloader/sabrina.BL33.encv12 of=$DIR/../bootloader/sabrina.bootloader.plain.img skip=$IN_OFFSET seek=$OUT_OFFSET bs=1 conv=notrunc
openssl enc -aes-256-cbc -nopad -e -K 7F9381074A7D1B42A7407EE83B112D9D9F6EAA74E402321C52734BDAA954511C -iv CE68BBE61FC7B79146E2C32ABF0E0A9B -in $DIR/../bootloader/sabrina.bootloader.plain.img -out $DIR/../bootloader/sabrina.bootloader.enc.img
dd if=$DIR/../bootloader/sabrina.bootloader.enc.img of=$DIR/../bootloader/sabrina.bootloader.bin seek=4096 bs=16 conv=notrunc
