#!/bin/sh

#  build_ffmpeg_x264_ios.sh
#
#
#  Created by DarkLinden on M/29/2013.
#

cd ffmpeg

echo "compile ffmpeg i386 ..."

make clean
rm -rf i386

./configure \
--cc=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/gcc' \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk \
--extra-ldflags=-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk/usr/lib/system \
--target-os=darwin \
--arch=i386 \
--cpu=i386 \
--extra-cflags='-I../x264 -arch i386' \
--extra-ldflags='-L../x264 -arch i386' \
--disable-ffmpeg  \
--disable-ffplay \
--disable-ffserver \
--disable-doc \
--disable-asm \
--enable-libx264 \
--enable-pic \
--enable-cross-compile \
--enable-gpl \
--enable-decoders \
--enable-encoders \
--disable-decoder=ac3 \
--disable-decoder=mlp

make

mkdir i386
find ./lib* -iname '*.a' | xargs -I {} mv {} i386


echo "compile ffmpeg armv7 ..."

make clean
rm -rf armv7

./configure \
--cc=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc' \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk \
--extra-ldflags=-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/usr/lib/system \
--target-os=darwin \
--arch=arm \
--cpu=cortex-a8 \
--extra-cflags='-I../x264 -arch armv7' \
--extra-ldflags='-L../x264 -arch armv7' \
--disable-ffmpeg  \
--disable-ffplay \
--disable-ffserver \
--disable-doc \
--disable-asm \
--enable-libx264 \
--enable-pic \
--enable-cross-compile \
--enable-gpl \
--enable-decoders \
--enable-encoders \
--disable-decoder=ac3 \
--disable-decoder=mlp

make

mkdir armv7
find ./lib* -iname '*.a' | xargs -I {} mv {} armv7


echo "compile ffmpeg armv7s ..."

make clean
rm -rf armv7s

./configure \
--prefix=armv7s \
--cc=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc \
--as='gas-preprocessor.pl /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/gcc' \
--sysroot=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk \
--extra-ldflags=-L/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk/usr/lib/system \
--target-os=darwin \
--arch=arm \
--cpu=cortex-a9 \
--extra-cflags='-I../x264 -arch armv7s' \
--extra-ldflags='-L../x264 -arch armv7s' \
--disable-ffmpeg  \
--disable-ffplay \
--disable-ffserver \
--disable-doc \
--disable-asm \
--enable-libx264 \
--enable-pic \
--enable-cross-compile \
--enable-gpl \
--enable-decoders \
--enable-encoders \
--disable-decoder=ac3 \
--disable-decoder=mlp

make

mkdir armv7s
find ./lib* -iname '*.a' | xargs -I {} mv {} armv7s

echo "lipo ffmpeg universal ..."
rm -rf lib
mkdir lib

echo "lipo ffmpeg libavcodec.a ..."
lipo -create "i386/libavcodec.a" "armv7/libavcodec.a" "armv7s/libavcodec.a" -output lib/libavcodec.a

echo "lipo ffmpeg libavdevice.a ..."
lipo -create "i386/libavdevice.a" "armv7/libavdevice.a" "armv7s/libavdevice.a" -output lib/libavdevice.a

echo "lipo ffmpeg libavfilter.a ..."
lipo -create "i386/libavfilter.a" "armv7/libavfilter.a" "armv7s/libavfilter.a" -output lib/libavfilter.a

echo "lipo ffmpeg libavformat.a ..."
lipo -create "i386/libavformat.a" "armv7/libavformat.a" "armv7s/libavformat.a" -output lib/libavformat.a

echo "lipo ffmpeg libavutil.a ..."
lipo -create "i386/libavutil.a" "armv7/libavutil.a" "armv7s/libavutil.a" -output lib/libavutil.a

echo "lipo ffmpeg libpostproc.a ..."
lipo -create "i386/libpostproc.a" "armv7/libpostproc.a" "armv7s/libpostproc.a" -output lib/libpostproc.a

echo "lipo ffmpeg libswresample.a ..."
lipo -create "i386/libswresample.a" "armv7/libswresample.a" "armv7s/libswresample.a" -output lib/libswresample.a

echo "lipo ffmpeg libswscale.a ..."
lipo -create "i386/libswscale.a" "armv7/libswscale.a" "armv7s/libswscale.a" -output lib/libswscale.a



