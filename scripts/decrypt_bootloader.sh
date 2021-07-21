#!/bin/sh

# decrypt bootloader partition, excluding BL2 [0x200:0x10000]
# note : AES key not provided
# Source : sabrina.bootloader.factory.2020-07-13.img - sha1:0b4a6f37fbd0744c0d19d8fae71e8d2c05acfafb - size:4194304 - version: 08:25:40, Jul 13 2020. g12a gfbd79d3 - mosaic-role@agent-us-east1-c-11.c.catabuilder-prod.internal

DIR=$(dirname $(realpath $0))
dd if=$DIR/../bootloader/sabrina.bootloader.factory.2020-07-13.img of=$DIR/../bootloader/sabrina.bootloader.enc.img skip=258 count=6314 bs=256
openssl enc -aes-256-cbc -nopad -d -K $key -iv $iv -in $DIR/../bootloader/sabrina.bootloader.enc.img -out $DIR/../bootloader/sabrina.bootloader.plain.img
