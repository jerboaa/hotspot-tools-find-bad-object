# Linker command for linking a new libjvm.so
# PRE: current working directory is a directory with
#      all required JVM objects
# 
# This usually comes from the build.log of an OpenJDK
# build with LOG=DEBUG
# 
# Change this to the appropriate link command.
/usr/bin/g++ -Wl,--hash-style=both -Wl,-z,defs -Wl,-z,noexecstack -Wl,-O1 -Wl,-z,relro -march=i586 -m32 -shared -m32 -Wl,-version-script=/openjdk-11/build/linux-x86-normal-server-release/hotspot/variant-server/libjvm/mapfile -Wl,-soname=libjvm.so -o libjvm.so @/hotspot-tools-find-bad-object/reproducers/i686-jdk11-rhbz1683095/objectfilenames.txt -lm -ldl -lpthread

# Please keep this
exit $?
