#!/usr/bin/env bash

let i=0
java_programs=()
while read -r line; do
	let i=$i+1
	java_programs+=($i "$line")
done < <(ls -1 *.java)

CHOICE=$(dialog --clear --title "Compile Java Program" --menu "Choose a Java program to compile" 15 40 4 "${java_programs[@]}" 3>&2 2>&1 1>&3)

clear

if [ $? -eq 0 ]; then
	FILE_CHOICE=$(ls -1 *.java | sed -n "`echo "$CHOICE p" | sed 's/ //'`")
fi

TEMP_DIR=$(mktemp -d)
STARTING_DIR=$(pwd)

if [ ! -e $TEMP_DIR ]; then
	>&2 echo "Failed to create temp directory"
	exit 1
fi

trap "exit 1" HUP INT PIPE QUIT TERM
trap 'rm -rf "$TEMP_DIR"' EXIT

cp "$FILE_CHOICE" "$TEMP_DIR"
cd "$TEMP_DIR"

filename=$(basename -- "$FILE_CHOICE")
filename="${filename%.*}"

echo "Main-Class: $filename" > MANIFEST.mf

javac "${filename}.java"
jar cmvf MANIFEST.mf output.jar *.class

mv *.jar "$STARTING_DIR"
cd "$STARTING_DIR"