#!/bin/bash
#
# Finds a bad object file (using binary search) from two
# OpenJDK builds. One that works, one that doesn't.
#

# Script to the reproducer expecting to fail for bad hotspot
# and to pass for good hotspot
REPRODUCER_SCRIPT="$(pwd)/reproducer.sh"

# The command for linking libjvm.so
# PRE: cd /path/to/hotspot
RELINK_JVM="$(pwd)/relink_jvm.sh"

# Do not change things below, please

LOG_FILE="$(pwd)/bisect_log.txt"
BAD_OBJECTS_LIST="$(pwd)/bad_objects_list.txt"

usage() {
  cat <<EOF
Usage:

BAD_HOTSPOT=/path/to/bad/hotspot/ \\
GOOD_HOTSPOT=/path/to/good/hostpot/ \\
JDK_IMAGE=/path/to/jdk-image \\
$0

Example OpenJDK 8:

BAD_HOTSPOT=$(pwd)/bad/build/hotspot/linux_amd64_compiler2/fastdebug/ \\
GOOD_HOTSPOT=$(pwd)/good/build/hotspot/linux_amd64_compiler2/fastdebug/ \\
JDK_IMAGE=$(pwd)/good/build/images/j2sdk-image/ \\
$0

Example OpenJDK 9:

BAD_HOTSPOT=$(pwd)/build/linux-ppc-normal-zero-fastdebug/bad-hotspot/variant-zero/libjvm/objs/ \\
GOOD_HOTSPOT=$(pwd)/build/linux-ppc-normal-zero-fastdebug/hotspot/variant-zero/libjvm/objs/ \\
JDK_IMAGE=$(pwd)/build/linux-ppc-normal-zero-slowdebug/images/jdk/ \\
$0

Where BAD_HOTSPOT fails the reproducer and GOOD_HOTSPOT passes the
reproducer. Determined by exit code 0 (== success) of the reproducer
script.
EOF
}

check_sanity() {
  local pass=1
  echo "Performing sanity checks of environment variables and support scripts ..."
  for var in BAD_HOTSPOT GOOD_HOTSPOT JDK_IMAGE; do
    if [ -z "${!var}" ]; then
      echo 1>&2 "The ${var} environment variable is required"
      pass=0
    fi
    if [ ! -d "${!var}" ]; then
      echo 1>&2 "${var}='${!var}': Directory '${!var}' does not exist!"
      pass=0
    fi
  done
  for var in REPRODUCER_SCRIPT RELINK_JVM; do
    if [ ! -e "${!var}" ]; then
      echo 1>&2 "${!var} does not exist!"
      pass=0
    fi
  done
  if [ ${pass} -eq 0 ]; then
    usage
    exit 1
  fi
  call_reproducer_sanity
  reproducer_sanity_with_linking
  echo "ALL sanity checks passed!"
}

# Call reproducer with good hotspot, then with bad. Assert, bad fails
# and good succeeds.
call_reproducer_sanity() {
  local retval=0
  bash $REPRODUCER_SCRIPT $GOOD_HOTSPOT $JDK_IMAGE > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo 1>&2 "Abort: ${GOOD_HOTSPOT} does NOT pass the reproducer! Expected it to pass."
    retval=1
  fi
  bash $REPRODUCER_SCRIPT $BAD_HOTSPOT $JDK_IMAGE > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo 1>&2 "Abort: ${BAD_HOTSPOT} PASSES the reproducer! Expected it to fail."
    retval=1
  fi
  if [ ${retval} -ne 0 ]; then
    usage
    exit 1
  fi
}

# Verify linking works. Remove libjvm.so, relink from objects and
# run reproducer on GOOD/BAD hotspots (same as call_reproducer_sanity)
reproducer_sanity_with_linking() {
  rm -f ${GOOD_HOTSPOT}/libjvm.so 
  rm -f ${BAD_HOTSPOT}/libjvm.so 
  relink_jvm ${GOOD_HOTSPOT}
  relink_jvm ${BAD_HOTSPOT}
  call_reproducer_sanity
}

split_list() {
  current_work_list_file=$1
  # global
  first_list=() # array
  second_list=() # array
  total=$( cat $current_work_list_file | wc -l )
  half=$(( $total / 2 ))
  echo "total objs = $total" >> $LOG_FILE
  echo "pivot = $half" >> $LOG_FILE
  counter=0
  idx=0
  for elem in $(cat $current_work_list_file); do
    # reset index
    if [ $counter -eq $half ]; then
      idx=0
    fi
    if [ $counter -lt $half ]; then
      # assign to first list
      first_list[${idx}]="${elem}"
    else
      second_list[${idx}]="${elem}"
    fi
    counter=$(( $counter + 1 ))
    idx=$(( $idx + 1 ))
  done
}

get_list() {
  list_=("${@}")
  for idx in $(seq 0 $(( ${#list_[@]} - 1 )) ); do
    echo "${list_[$idx]}"
  done
}

get_first_list() {
  get_list ${first_list[@]}
}

get_second_list() {
  get_list ${second_list[@]}
}

create_good() {
  target_dir=$1
  rm -rf $target_dir
  cp -r $GOOD_HOTSPOT $target_dir
}

copy_bad_over_good() {
  target_dir=$1
  shift
  bad_list=("${@}")
  # copy bad list into target dir
  cp $(get_list ${bad_list[@]}) $target_dir
}

relink_jvm() {
  target_dir=$1
  old_dir="$(pwd)"
  echo "linking jvm in $target_dir" >> $LOG_FILE
  cd $target_dir
  bash $RELINK_JVM
  retval=$?
  cd $old_dir
  if [ $retval -ne 0 ]; then
     echo "linking libjvm.so failed for $target_dir Exiting now." 1>&2
     exit 10
  fi
}

# Make sure scripts are sane, required variables are defined
check_sanity

echo "Starting binary search in order to find bad object file ..."
echo "  Use 'tail -f ${LOG_FILE}' to follow progress"
# create file with intermediate list of objects
ls $BAD_HOTSPOT/*.o > $BAD_OBJECTS_LIST
split_list $BAD_OBJECTS_LIST

while true; do
  # start the loop
  first_list_file="$(pwd)/first_list.txt"
  second_list_file="$(pwd)/second_list.txt"
  FIRST_COPY="$(pwd)/first-copy"
  SECOND_COPY="$(pwd)/second-copy"
  first_log="$FIRST_COPY/reproducer_run.log"
  second_log="$SECOND_COPY/reproducer_run.log"
  for copy in $FIRST_COPY $SECOND_COPY; do
    create_good $copy
  done
  copy_bad_over_good $FIRST_COPY ${first_list[@]}
  copy_bad_over_good $SECOND_COPY ${second_list[@]}
  get_first_list > "$first_list_file"
  get_second_list > "$second_list_file"
  for copy in $FIRST_COPY $SECOND_COPY; do
    relink_jvm $copy
  done

  # run the reproducer on first and second copy
  bash $REPRODUCER_SCRIPT $FIRST_COPY $JDK_IMAGE >> $first_log 2>&1
  first_exit=$?
  bash $REPRODUCER_SCRIPT $SECOND_COPY $JDK_IMAGE >> $second_log 2>&1
  second_exit=$?
  if [ $first_exit -ne 0 ] && [ $second_exit -ne 0 ]; then
    echo "Both copies bad? Picking first copy arbitrarily..." 1>&2
    second_exit=0
  fi
  if [ $first_exit -eq 0 ] && [ $second_exit -eq 0 ]; then
    echo "Both copies good? Unexpected. Exiting" 1>&2
    exit 20
  fi
  if [ $first_exit -eq 0 ]; then
    i="$(get_second_list)"
    echo "second list contained bad object file: $i" >> $LOG_FILE
    mv $second_list_file $BAD_OBJECTS_LIST
    rm $first_list_file
  else
    i="$(get_first_list)"
    echo "first list contained bad object file: $i" >> $LOG_FILE
    mv $first_list_file $BAD_OBJECTS_LIST
    rm $second_list_file
  fi
  rm -f hotspot*.log hs_err_pid*.log replay_pid*.log

  # terminate loop once no more objects to split
  num_objs=$(cat $BAD_OBJECTS_LIST | wc -l)
  if [ $num_objs -le 1 ]; then
    bad_obj="$(cat $BAD_OBJECTS_LIST)"
    echo "found bad object: $bad_obj"
    exit 0
  fi
  echo "----- splitting bad list file -------- " >> $LOG_FILE
  split_list $BAD_OBJECTS_LIST
done
