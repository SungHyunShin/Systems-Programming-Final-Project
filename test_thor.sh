#!/bin/bash

PROGRAM=thor.py
WORKSPACE=/tmp/$PROGRAM.$(id -u)
FAILURES=0

# Functions

error() {
    echo "$@"
    [ -r $WORKSPACE/test ] && (echo; cat $WORKSPACE/test; echo)
    FAILURES=$((FAILURES + 1))
}

cleanup() {
    STATUS=${1:-$FAILURES}
    rm -fr $WORKSPACE
    exit $STATUS
}

check_status() {
    if [ $1 -ne $2 ]; then
	echo "FAILURE: exit status $1 != $2" > $WORKSPACE/test
	return 1;
    fi

    return 0;
}

check_md5sum() {
    cksum=$(grep -E -v '^(Process|TOTAL)' $WORKSPACE/test | md5sum | awk '{print $1}') 
    if [ $cksum != $1 ]; then
	echo "FAILURE: md5sum $cksum != $1" > $WORKSPACE/test
	return 1;
    fi
}

grep_all() {
    for pattern in $1; do
    	if ! grep -q -E "$pattern" $2; then
    	    echo "FAILURE: Missing '$pattern' in '$2'" > $WORKSPACE/test
    	    return 1;
    	fi
    done
    return 0;
}

grep_count() {
    if [ $(grep -i -c $1 $WORKSPACE/test) -ne $2 ]; then
	echo "FAILURE: $1 count != $2" > $WORKSPACE/test
	return 1;
    fi
    return 0;
}

# Setup

mkdir $WORKSPACE

trap "cleanup" EXIT
trap "cleanup 1" INT TERM

# Testing

echo "Testing $PROGRAM..."

# ------------------------------------------------------------------------------

printf " %-72s ... " "Functions"
if ! grep_all "multiprocessing.Pool requests.get map time.time" $PROGRAM; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-72s\n" "Usage"

printf "     %-68s ... " "no arguments"
./$PROGRAM &> $WORKSPACE/test
if ! check_status $? 1 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "bad arguments"
./$PROGRAM -b -a -d &> $WORKSPACE/test
if ! check_status $? 1 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "-h"
./$PROGRAM -h &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

PATTERNS="Process Request Elapsed Time TOTAL AVERAGE"

printf "\n %-72s\n" "Single Process"

DOMAIN=https://example.com
MD5SUM=f794452c7a373a8b8d5919e1f0975ffc
printf "     %-68s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=4d607388d10cf7b2a0ed28dcede8c726
printf "     %-68s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=5ee3cd546314fab3dc9cc4ab058a9005
printf "     %-68s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-72s\n" "Single Process, Multiple Requests"

DOMAIN=https://example.com
MD5SUM=14cd97e511727205c407a9440ac23de4
printf "     %-68s ... " "$DOMAIN (-r 5)"
./$PROGRAM -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-r 5 -v)"
./$PROGRAM -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=c53d6f39c866142d57ffe13bff3cfb73
printf "     %-68s ... " "$DOMAIN (-r 5)"
./$PROGRAM -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-r 5 -v)"
./$PROGRAM -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=3861cedcae586a1af3d80d5da33c033b
printf "     %-68s ... " "$DOMAIN (-r 5)"
./$PROGRAM -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-r 5 -v)"
./$PROGRAM -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 6 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-72s\n" "Multiple Processes"

DOMAIN=https://example.com
MD5SUM=14cd97e511727205c407a9440ac23de4
printf "     %-68s ... " "$DOMAIN (-p 5)"
./$PROGRAM -p 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -v)"
./$PROGRAM -p 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=c53d6f39c866142d57ffe13bff3cfb73
printf "     %-68s ... " "$DOMAIN (-p 5)"
./$PROGRAM -p 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -v)"
./$PROGRAM -p 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=3861cedcae586a1af3d80d5da33c033b
printf "     %-68s ... " "$DOMAIN (-p 5)"
./$PROGRAM -p 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -v)"
./$PROGRAM -p 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 5; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-72s\n" "Multiple Processes, Multiple Requests"

DOMAIN=https://example.com
MD5SUM=78de4ea6c37329f5c5b8898e3b9a4ab4
printf "     %-68s ... " "$DOMAIN (-p 5 -r 5)"
./$PROGRAM -p 5 -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -r 5 -v)"
./$PROGRAM -p 5 -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=ca7f9c3840302b34267032cc54adf9ba
printf "     %-68s ... " "$DOMAIN (-p 5 -r 5)"
./$PROGRAM -p 5 -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -r 5 -v)"
./$PROGRAM -p 5 -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=512f4378eb1cd3ea9b6386ed5e933d4d
printf "     %-68s ... " "$DOMAIN (-p 5 -r 5)"
./$PROGRAM -p 5 -r 5 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-68s ... " "$DOMAIN (-p 5 -r 5 -v)"
./$PROGRAM -p 5 -r 5 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 30 || ! grep_count Request 25; then
    error "Failure"
else
    echo "Success"
fi
