#!/bin/bash

set -e

if [ $# -eq 0 ]
then
  echo Usage: $0 text
  exit 1
fi

output_file=/tmp/${USER}_gnuspeechcli.wav

opentool GnuSpeechCLI config $output_file "$*"

aplay $output_file
