#!/usr/bin/env bash


if [ "$1" = "build-clean" ]
then
    hrclean.sh
elif [ "$1" = "make" ]
then
    hrmk.sh
else
    echo "Please use arguments as make or build-clean"
fi