#!/bin/bash

set -o errexit

export FILE_LOG=z_log.txt
export FILE_LOG_SETUP=z_log_setup.txt
export FILE_OUT=z_out.txt
# export LOG_MODE=shape
export LOG_MODE=file
export ENABLE_LOG=0
export RUN_MODE=gui

ruby libo.rb render "A"

libreoffice z_000.fods
