#!/bin/bash

export ARCH=arm64
export CROSS_COMPILE=toolchain/bin/aarch64-linux-gnu-

if [ -f ".config" ]
then
	echo ".config found"
else
	cp defconfig .config
fi

if [ -d "toolchain" ]
then
	echo "toolchain found"
else
	wget "https://developer.arm.com/-/media/Files/downloads/gnu-a/8.3-2019.03/binrel/gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz" -O gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
	tar xf gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
	mv gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu toolchain
	rm gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu.tar.xz
fi

make -j$(($(nproc) + 1)) # Build everything (comment as you wish)
# make modules -j$(($(nproc) + 1)) # Build only modules (comment as you wish)
mkdir -p output/modules/vendor/lib/modules/$(uname -r)

find . -name '*.cpio.gz' -exec cp '{}' output \;
find . -name 'config_data.gz' -exec cp '{}' output \;
find . -name '*gz-dtb' -exec cp '{}' output \;
find . -name '*.ko' -exec cp -rf '{}' output/modules/vendor/lib/modules/$(uname -r) \;
mv modules.* output/modules/vendor/lib/modules/$(uname -r)
mv Module.symvers output/modules/vendor/lib/modules/$(uname -r)

depmod -b output/modules/vendor
mv output/modules/vendor/lib/modules/$(uname -r)/* output/modules/vendor/lib/modules/
rm -r output/modules/vendor/lib/modules/$(uname -r)

cd output
zip -uj pocophone_kernel.zip Image.gz-dtb
zip -ur pocophone_kernel.zip modules
cd ../

if [ -z "$CI" ]
then
      adb push output/pocophone_kernel.zip /sdcard/pocophone_kernel.zip
else
      echo "Not uploading kernel"
fi