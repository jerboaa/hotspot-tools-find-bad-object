# Be sure paths to object files are relative in:
# /openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/hotspot/variant-zero/libjvm/objs/_BUILD_LIBJVM_objectfilenames.txt
/usr/bin/g++ \
-Wl,--hash-style=both -Wl,-z,defs -Wl,-z,noexecstack -Wl,-O1 -Wl,-z,relro -shared \
-Wl,-version-script=/openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/hotspot/variant-zero/libjvm/mapfile \
-Wl,-soname=libjvm.so -o libjvm.so \
@/openjdk9-hs-comp/build/linux-ppc-normal-zero-fastdebug/hotspot/variant-zero/libjvm/objs/_BUILD_LIBJVM_objectfilenames.txt -lm -ldl -lpthread -lffi
