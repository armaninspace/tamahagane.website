#!/usr/bin/env bash

SLocation="`dirname \"$0\"`"

Rscript $SLocation/../R/hrocket.R $SLocation build-clean
