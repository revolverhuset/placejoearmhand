#!/bin/bash

set -e

function urldecode()
{
	python -c "import sys, urllib as ul; print ul.unquote_plus(sys.argv[1])" "$1"
}

echo "$QUERY_STRING" >> debug

saveIFS=$IFS
IFS='=&'
SPLIT_QUERY_STRING=($QUERY_STRING)
IFS=$saveIFS

declare -A QUERY
for ((i=0; i<${#SPLIT_QUERY_STRING[@]}; i+=2))
do
    QUERY[${SPLIT_QUERY_STRING[i]}]=${SPLIT_QUERY_STRING[i+1]}
done

SRC="${QUERY[src]}"

if [ -z "$SRC" ]
then
	SRC="${QUERY[text]}"
fi

if [ -z "$SRC" ]
then
	echo "Content-Type: text/html;charset=utf8"
	echo "Cache-Control: public,max-age=31556926"
	echo
	cat placejoearmhand.html
	exit 1
fi

SRC="$(urldecode "$SRC")"

if ! [[ $SRC == http://* ]] && ! [[ $SRC == https://* ]]
then
	echo "Content-Type: text/plain"
	echo
	echo "src must be http or https"
	exit 1
fi

function generate_imagemagick() {
	echo -n "convert \"$1\" "
	../facedetect/facedetect $1 | while IFS= read -r FACE ; do
		DIMS=($FACE)
		LEFT=${DIMS[0]}
		TOP=${DIMS[1]}
		WIDTH=${DIMS[2]}
		HEIGHT=${DIMS[3]}
		echo -n "-draw 'image over $(( LEFT-WIDTH*2/5 )),$(( TOP+HEIGHT/2 )),$(( WIDTH )),$(( HEIGHT )) joearmhand.png' "
	done
	echo "jpeg:-"
}

IMG_FILE=$(mktemp)
trap "rm \$IMG_FILE" EXIT

curl "$SRC" > "$IMG_FILE"
IMAGEMAGICK="$( generate_imagemagick "$IMG_FILE" )"

echo "Content-Type: image/jpeg"
echo "Cache-Control: public,max-age=31556926"
echo
eval "$IMAGEMAGICK"
