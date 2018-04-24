#!/usr/bin/env bash

SLocation="`dirname \"$0\"`"

Rscript $SLocation/../libs/hrocket.R $SLocation build-clean
