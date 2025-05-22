#!/usr/bin/bash
FILE=$1
grep "^[^.]*\.[^.]*$" $FILE
