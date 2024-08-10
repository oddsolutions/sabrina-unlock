#!/bin/bash

for partition in odm product system vendor
do
brotli --decompress --output=$partition.new.dat $partition.new.dat.br
sdat2img $partition.transfer.list $partition.new.dat $partition.img
done
