#!/bin/bash

export LIBO_HEADLESS=1
export ENABLE_LOG=0
export RUN_MODE=cli

ruby stepA_mal.rb "$@"
