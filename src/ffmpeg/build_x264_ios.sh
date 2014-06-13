#!/bin/sh

#  build_x264_ios.sh
#
#
#  Created by DarkLinden on M/29/2013.
#

cd x264

rm -rf build

#build armv7

echo "compile x264 armv7 ..."

make clean

CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc" \
./configure \
--host=arm-apple-darwin \
--prefix="build/armv7" \
--sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk" \
--extra-cflags='-arch armv7' \
--extra-ldflags="-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneoS6.1.sdk/usr/lib/system -arch armv7" \
--enable-pic \
--enable-shared \
--enable-static

make && make install

#build armv7s

echo "compile x264 armv7s ..."

make clean

CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc" \
./configure \
--host=arm-apple-darwin \
--prefix="build/armv7s" \
--sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk" \
--extra-cflags='-arch armv7s' \
--extra-ldflags="-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneoS6.1.sdk/usr/lib/system -arch armv7s" \
--enable-pic \
--enable-shared \
--enable-static

make && make install

#build i386

echo "compile x264 i386 ..."

make clean

CC="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc" \
./configure \
--host=i386-apple-darwin \
--prefix="build/i386" \
--sysroot="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk" \
--extra-cflags='-arch i386' \
--extra-ldflags="-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk/usr/lib/system -arch i386" \
--enable-pic \
--enable-shared \
--enable-static

make && make install

#lipo to one

echo "lipo x264 universal ..."

lipo -create "build/i386/lib/libx264.a" "build/armv7/lib/libx264.a" "build/armv7s/lib/libx264.a" -output libx264.a