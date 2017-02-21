Hotspot JVM scripts
===================

Find a bad object file in Hotspot's libjvm.so. A bad object file might be produced
by using a new compiler version. The reason as to why an object file might be bad
is usually one of:

 * A compiler bug
 * A bug in Hotspot (usually use of undefined behaviour)

Usage
=====

First, produce two identical builds of OpenJDK. Same optimization level, same
everything. For example a `fastdebug` build and a `release` build will likely
not work, since the script links a combination of the objects of the two builds
together to form a JVM to test the reproducer against.

A "good" build can usually be produced by disabling some compiler optimizations,
usually the ones that got added/changed recently.

Once you have two builds, and a reproducer and the link command, edit
`reproducer.sh` to use your reproducer. Do the same for `relink_jvm.sh`. You
can find the link command from the build.log of an OpenJDK build.

Then invoke the main script like this:

    BAD_HOTSPOT=/path/to/bad/hotspot/ \
    GOOD_HOTSPOT=/path/to/good/hostpot/ \
    JDK_IMAGE=/path/to/jdk-image \
    ./find_bad_object.sh


Example output:

    ALL sanity checks passed!
    Starting binary search in order to find bad object file ...
      Use 'tail -f /builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/bisect_log.txt' to follow progress
    Found bad object: /builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/build/jdk8.build/hotspot/linux_amd64_compiler2/fastdebug//psParallelCompact.o
