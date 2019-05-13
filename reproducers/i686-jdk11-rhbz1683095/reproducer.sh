#!/bin/bash
#
# Usage:
# reproducer.sh </path/to/hotspot> </path/to/jdk-image>
HOTSPOT=$1
JDK=$2
# Retrieved from JDK 11 test sources
export JAVA_HOME=$JDK
GC_BASHER_CLASSES=/gc-basher-classes
for i in $(seq 50); do
  ${JDK}/bin/java \
    -XXaltjvm=$HOTSPOT \
    -Dsun.java.launcher.is_altjvm=true \
    -cp $GC_BASHER_CLASSES \
    -XX:MaxRAMPercentage=6 -Xmx256m \
    -XX:+UseG1GC TestGCBasherWithG1 120000
  retval=$?
  echo "iteration $i"
  if [ $retval -ne 0 ]; then
    exit $retval
  fi
done
exit $retval
