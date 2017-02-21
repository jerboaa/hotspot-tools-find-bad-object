# Reproducer script taking in two arguments:
# - The directory with hotspot's libjvm.so
# - The directory of the JDK image
#
# Usage:
# reproducer.sh </path/to/hotspot> </path/to/j2sdk-image>
HOTSPOT_DIR=$1
JDK_IMAGE=$2

JAVA_HOME=${JDK_IMAGE} \
 ${JDK_IMAGE}/bin/java \
 -cp ${JDK_IMAGE}/lib/tools.jar:${JDK_IMAGE}/classes \
 -Dapplication.home=${JDK_IMAGE} \
 -Xms8m \
 -XXaltjvm=$HOTSPOT_DIR \
 -Dsun.java.launcher=gamma \
 com.sun.tools.javac.Main -XDignore.symbol.file=true -g -Xlint:all,-deprecation -Werror -g -implicit:none -sourcepath /builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/langtools/src/share/classes:/builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/build/jdk8.build/bootcycle-build/langtools/gensrc -d /builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/build/jdk8.build/bootcycle-build/langtools/btclasses/bootstrap @/builddir/build/BUILD/java-1.8.0-openjdk-1.8.0.121-5.b14.fc26.x86_64/openjdk/build/jdk8.build/bootcycle-build/langtools/btclasses/bootstrap/_the.BUILD_BOOTSTRAP_LANGTOOLS_batch.tmp
exit $?
