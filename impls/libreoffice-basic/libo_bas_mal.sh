#!/bin/bash

export LIBO_HEADLESS=1
export ENABLE_LOG=0

ruby stepA_mal.rb "$@"
