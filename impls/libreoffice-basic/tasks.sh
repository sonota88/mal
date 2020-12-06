#!/bin/bash

readonly FILES_DIR=z_files/

cmd_test() {
  set -o errexit

  src_step="$1"; shift
  test_step="$1"; shift

  cmd_reset

  export NO_COLOR=1
  export LIBO_HEADLESS=1
  export ENABLE_LOG=0
  export RUN_MODE=cli

  # 1: テストに不要な出力を出さないようにするなど
  #   テストを通すための措置
  export IS_TEST=1

  export SRC_STEP=${src_step}

  time (
    cd ../../
    make "test^libreoffice-basic^step${test_step}"
    if [ $? -ne 0 ]; then
      echo "!!!! NG !!!!"
    else
      echo "ok"
    fi
  )
}

cmd_test_mal() {
  step="$1"

  cmd_reset

  export NO_COLOR=1
  export LIBO_HEADLESS=1
  export ENABLE_LOG=0
  export IS_TEST=1
  export RUN_MODE=cli

  (
    cd ../../
    # make MAL_IMPL=ruby "test^mal^step${step}"
    make MAL_IMPL=libreoffice-basic "test^mal^step${step}"
  )
}

cmd_repl() {
  export LIBO_HEADLESS=1
  export ENABLE_LOG=0
  export RUN_MODE=cli

  ruby libo.rb step stepA "$@"
}

cmd_run_gui() {
  set -o errexit

  export FILE_LOG=${FILES_DIR}/log.txt
  export FILE_LOG_SETUP=${FILES_DIR}/log_setup.txt
  export FILE_OUT=${FILES_DIR}/out.txt
  # export LOG_MODE=shape
  export LOG_MODE=file
  export ENABLE_LOG=0
  export RUN_MODE=gui

  ruby libo.rb render "A"

  libreoffice ${FILES_DIR}/temp.fods
}

cmd_reset() {
  echo -n "" > ${FILES_DIR}/hist.txt
}

# --------------------------------

cmd="$1"; shift
case $cmd in
  test)       #desc: Run test
    cmd_test "$@"
    ;;
  test-mal)   #desc: Run test (mal)
    cmd_test_mal "$@"
    ;;
  render)     #desc: Render fods file
    ruby libo.rb render "A"
    ;;
  repl)       #desc: Try repl
    cmd_repl "$@"
    ;;
  run-gui)    #desc: Run in gui mode
    cmd_run_gui "$@"
    ;;
  reset)      #desc: Reset
    cmd_reset "$@"
    ;;
  *)
    echo "invalid command: ${cmd}" >&2

    echo "tasks:"
    cat $0 | grep '#desc: ' | grep -v grep

    exit 1
    ;;
esac
