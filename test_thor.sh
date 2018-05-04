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
    cksum=$(grep -E -v '^(Process|TOTAL)' $WORKSPACE/test | sed -E '/^\s*$/d' | md5sum | awk '{print $1}')
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

printf " %-64s ... " "Functions"
if ! grep_all "multiprocessing.Pool requests.get map time.time" $PROGRAM; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-64s\n" "Usage"

printf "     %-60s ... " "no arguments"
./$PROGRAM &> $WORKSPACE/test
if ! check_status $? 1 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "bad arguments"
./$PROGRAM -b -a -d &> $WORKSPACE/test
if ! check_status $? 1 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "-h"
./$PROGRAM -h &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "Usage" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

PATTERNS="Process Request Elapsed Time TOTAL AVERAGE"

printf "\n %-64s\n" "Single Process"

DOMAIN=https://example.com
MD5SUM=491dc0a7a6969aa2b10d424835d37e0b
printf "     %-60s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=408695c9aacff7faaec9796ef176219f
printf "     %-60s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=1877fcda6f85fa183220fdb47ecdbb9d
printf "     %-60s ... " "$DOMAIN"
./$PROGRAM $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-v)"
./$PROGRAM -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-64s\n" "Single Process, Multiple Requests"

DOMAIN=https://example.com
MD5SUM=a086e506ace1405a4da43e11ac1ff9e4
printf "     %-60s ... " "$DOMAIN (-r 4)"
./$PROGRAM -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-r 4 -v)"
./$PROGRAM -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=9b24fe29a1b0f5b18f3840da9fe0d32f
printf "     %-60s ... " "$DOMAIN (-r 4)"
./$PROGRAM -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-r 4 -v)"
./$PROGRAM -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=a44c9b1df78e3656398db9ba92548a56
printf "     %-60s ... " "$DOMAIN (-r 4)"
./$PROGRAM -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-r 4 -v)"
./$PROGRAM -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 5 || ! grep_count Request 4; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-64s\n" "Multiple Processes"

DOMAIN=https://example.com
MD5SUM=70f0122be77ab9a12f8767bd04945a19
printf "     %-60s ... " "$DOMAIN (-p 2)"
./$PROGRAM -p 2 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -v)"
./$PROGRAM -p 2 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=2d00d24794150a21eb9fe4f4361623bb
printf "     %-60s ... " "$DOMAIN (-p 2)"
./$PROGRAM -p 2 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -v)"
./$PROGRAM -p 2 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=9df2453cf04874e6ca1124f8e49f2051
printf "     %-60s ... " "$DOMAIN (-p 2)"
./$PROGRAM -p 2 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -v)"
./$PROGRAM -p 2 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 4 || ! grep_count Request 2; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-64s\n" "Multiple Processes, Multiple Requests"

DOMAIN=https://example.com
MD5SUM=8ef96d0b3be2d7dffcfb482971330ca7
printf "     %-60s ... " "$DOMAIN (-p 2 -r 4)"
./$PROGRAM -p 2 -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -r 4 -v)"
./$PROGRAM -p 2 -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me
MD5SUM=e0d12f1611dc4d8a1f0f7bd4dfd9b0f6
printf "     %-60s ... " "$DOMAIN (-p 2 -r 4)"
./$PROGRAM -p 2 -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -r 4 -v)"
./$PROGRAM -p 2 -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi

DOMAIN=https://yld.me/izE?raw=1
MD5SUM=ce4d6bbaca157f968e6e57aa084e6ec1
printf "     %-60s ... " "$DOMAIN (-p 2 -r 4)"
./$PROGRAM -p 2 -r 4 $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0     || ! grep_all "$PATTERNS" $WORKSPACE/test || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi

printf "     %-60s ... " "$DOMAIN (-p 2 -r 4 -v)"
./$PROGRAM -p 2 -r 4 -v $DOMAIN &> $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$PATTERNS" $WORKSPACE/test || ! check_md5sum $MD5SUM || \
   ! grep_count Process 10 || ! grep_count Request 8; then
    error "Failure"
else
    echo "Success"
fi
