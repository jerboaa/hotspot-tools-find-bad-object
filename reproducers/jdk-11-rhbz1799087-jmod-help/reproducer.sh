#!/bin/bash
HOTSPOT=$1
JDK=$2
export JAVA_HOME=$JDK
  ${JDK}/bin/jmod \
    -J-XXaltjvm=$HOTSPOT \
    -J-Dsun.java.launcher.is_altjvm=true \
    --help
  retval=$?
exit $retval
