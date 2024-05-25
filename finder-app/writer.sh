#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Error: Two arguments are required: <file path> <write string>"
    exit 1
fi

writefile=$1
writestr=$2

mkdir -p $(dirname "$writefile")

if [ $? -ne 0 ]; then
    echo "Error: Could not create directory $dirpath"
    exit 1
fi

echo "$writestr" > "$writefile"
if [ $? -ne 0 ]; then
    echo "Error: Could not write to file $writefile"
    exit 1
fi