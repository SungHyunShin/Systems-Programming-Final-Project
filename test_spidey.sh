#!/bin/bash

PROGRAM=spidey
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
    cksum=$(md5sum $WORKSPACE/test | awk '{print $1}')
    if [ $cksum != $1 ]; then
	echo "FAILURE: md5sum $cksum != $1" > $WORKSPACE/test
	return 1;
    fi
}

check_header() {
    status=$(head -n 1 $WORKSPACE/header | tr -d '\r\n')
    content=$(awk '/Content/ { print $2 }' $WORKSPACE/header | tr -d '\r\n')
    if [ "$status" != "$1" ]; then
	echo "FAILURE: $status != $1" > $WORKSPACE/test
	return 1;
    fi
    if [ "$content" != "$2" ]; then
	echo "FAILURE: content-type: $content != $2" > $WORKSPACE/test
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

check_hrefs() {
    if [ "$(sed -En 's/.*href="([^"]+)".*/\1/p' $WORKSPACE/test | sort | paste -s -d ,)" != $1 ]; then
	echo "FAILURE: hrefs != $1" > $WORKSPACE/test
	return 1;
    fi
}

# Setup

mkdir $WORKSPACE

trap "cleanup" EXIT
trap "cleanup 1" INT TERM

# Testing

# ------------------------------------------------------------------------------

echo
cowsay -W 72 <<EOF
On another machine, please run:

    valgrind --leak-check=full ./spidey -r ~pbui/pub/www -p PORT -c MODE

- Where PORT is a number between 9000 - 9999

- Where MODE is either single or forking
EOF
echo

HOST="$1"
while [ -z "$HOST" ]; do
    read -p "Server Host: " HOST
done

PORT="$2"
while [ -z "$PORT" ]; do
    read -p "Server Port: " PORT
done

echo
echo "Testing spidey server on $HOST:$PORT ..."

# ------------------------------------------------------------------------------

printf "\n %-64s ... \n" "Handle Browse Requests"

printf "     %-60s ... " "/"
HREFS="/..,/html,/scripts,/song.txt,/text"
STATUS="HTTP/1.0 200 OK"
CONTENT="text/html"
curl -s -D $WORKSPACE/header $HOST:$PORT/ > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all ".. html scripts text" $WORKSPACE/test || ! check_hrefs $HREFS || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/html"
HREFS="/html/..,/html/index.html"
curl -s -D $WORKSPACE/header $HOST:$PORT/html > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all ".. index.html" $WORKSPACE/test || ! check_hrefs $HREFS || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/scripts"
HREFS="/scripts/..,/scripts/cowsay.sh,/scripts/env.sh"
curl -s -D $WORKSPACE/header $HOST:$PORT/scripts > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all ".. cowsay.sh env.sh" $WORKSPACE/test || ! check_hrefs $HREFS || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/text"
HREFS="/text/..,/text/hackers.txt,/text/lyrics.txt"
curl -s -D $WORKSPACE/header $HOST:$PORT/text > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all ".. hackers.txt lyrics.txt" $WORKSPACE/test || ! check_hrefs $HREFS || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

# ------------------------------------------------------------------------------

printf "\n %-64s ... \n" "Handle File Requests"

printf "     %-60s ... " "/html/index.html"
MD5SUM=55cdbe19dcf3ea685707213cdada01ef
STATUS="HTTP/1.0 200 OK"
CONTENT="text/html"
curl -s -D $WORKSPACE/header $HOST:$PORT/html/index.html > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "avengers Spidey html" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/text/hackers.txt"
MD5SUM=c77059544e187022e19b940d0c55f408
CONTENT="text/plain"
curl -s -D $WORKSPACE/header $HOST:$PORT/text/hackers.txt > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "criminal Damn kids beauty Mentor" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/text/lyrics.txt"
MD5SUM=083de1aef4143f2ec2ef7269700a6f07
curl -s -D $WORKSPACE/header $HOST:$PORT/text/lyrics.txt > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "love me close eyes" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/song.txt"
MD5SUM=e2c99a8ac0448f1731084b29fc64462d
curl -s -D $WORKSPACE/header $HOST:$PORT/song.txt > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "you forget her" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

# ------------------------------------------------------------------------------

printf "\n %-64s ... \n" "Handle CGI Requests"

printf "     %-60s ... " "/scripts/env.sh"
CONTENT="text/plain"
HEADERS="DOCUMENT_ROOT QUERY_STRING REMOTE_ADDR REMOTE_PORT REQUEST_METHOD REQUEST_URI SCRIPT_FILENAME SERVER_PORT HTTP_HOST HTTP_USER_AGENT"
curl -s -D $WORKSPACE/header $HOST:$PORT/scripts/env.sh > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "$HEADERS" $WORKSPACE/test || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/scripts/cowsay.sh"
MD5SUM=ddc37544d37e4ff1ca8c43eae6ff0f9d
CONTENT="text/html"
curl -s -D $WORKSPACE/header $HOST:$PORT/scripts/cowsay.sh > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "Cowsay surgery daemon cheese sheep" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/scripts/cowsay.sh?message=hi"
MD5SUM=4b88cc20abfb62fe435c55e98f23ff43
CONTENT="text/html"
curl -s -D $WORKSPACE/header $HOST:$PORT/scripts/cowsay.sh?message=hi > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "Cowsay surgery daemon cheese sheep" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "/scripts/cowsay.sh?message=hi&template=vader"
MD5SUM=91bd83301e691e52406f9bf8722ae5fc
CONTENT="text/html"
curl -s -D $WORKSPACE/header "$HOST:$PORT/scripts/cowsay.sh?message=hi&template=vader" > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "Cowsay surgery daemon cheese sheep" $WORKSPACE/test || ! check_md5sum $MD5SUM || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

# ------------------------------------------------------------------------------

printf "\n %-64s ... \n" "Handle Errors"

printf "     %-60s ... " "/asdf"
STATUS="HTTP/1.0 404 Not Found"
CONTENT="text/html"
curl -s -D $WORKSPACE/header $HOST:$PORT/asdf > $WORKSPACE/test
if ! check_status $? 0 || ! grep_all "404" $WORKSPACE/test || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "Bad Request"
STATUS="HTTP/1.0 400 Bad Request"
CONTENT="text/html"
nc $HOST $PORT <<<"DERP" |& tee $WORKSPACE/test $WORKSPACE/header > /dev/null
if ! check_status $? 0 || ! grep_all "400" $WORKSPACE/test || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi

sleep 2

printf "     %-60s ... " "Bad Headers"
STATUS="HTTP/1.0 400 Bad Request"
CONTENT="text/html"
printf "GET / HTTP/1.0\r\nHost\r\n" | nc $HOST $PORT |& tee $WORKSPACE/test $WORKSPACE/header > /dev/null
if ! check_status $? 0 || ! grep_all "400" $WORKSPACE/test || ! check_header "$STATUS" "$CONTENT"; then
    error "Failure"
else
    echo "Success"
fi
