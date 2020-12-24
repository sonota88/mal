#!/bin/bash

print_this_dir() {
  (
    cd "$(dirname "$0")"
    pwd
  )
}

readonly FILES_DIR=$(print_this_dir)/z_files/
readonly FAILED_STEPS_FILE=${FILES_DIR}/failed_steps.txt

cmd_test() {
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
      echo "step $test_step" >> $FAILED_STEPS_FILE
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
    if [ $? -ne 0 ]; then
      echo "!!!! NG !!!!"
      echo "mal step $test_step" >> $FAILED_STEPS_FILE
    else
      echo "ok"
    fi
  )
}

cmd_test_all() {
  if [ -e $FAILED_STEPS_FILE ]; then
    rm $FAILED_STEPS_FILE
  fi

  for test_step in 2 3 4 5 6 7 8 9 A; do
    cmd_test A $test_step
  done

  for test_step in 2 3 4 6 7 8 9 A; do
    cmd_test_mal $test_step
  done

  echo "----------------"
  if [ -e $FAILED_STEPS_FILE ]; then
    echo "!!!! NG !!!!"
    cat $FAILED_STEPS_FILE
  else
    echo "ok"
  fi
}

cmd_repl() {
  ruby docker_setup.rb

  export LIBO_HEADLESS=1
  export ENABLE_LOG=0
  export RUN_MODE=cli

  touch .mal-history
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


cmd_docker_build() {
  docker build -t libreoffice_basic_mal:trial .
}

cmd_docker_run() {
  docker run --rm -it -v "$(pwd):/root/work" \
    libreoffice_basic_mal:trial \
    bash
}

cmd_docker_repl() {
  docker run --rm -it -v "$(pwd):/root/work" \
    libreoffice_basic_mal:trial \
    bash tasks.sh repl
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
  test-all)   #desc: Run all tests
    cmd_test_all "$@"
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
  docker-build) #desc: Build Docker image
    cmd_docker_build "$@"
    ;;
  docker-run)  #desc: Docker run
    cmd_docker_run "$@"
    ;;
  docker-repl)  #desc: Try repl in Docker container
    cmd_docker_repl "$@"
    ;;
  *)
    echo "invalid command: ${cmd}" >&2

    echo "tasks:"
    cat $0 | grep '#desc: ' | grep -v grep

    exit 1
    ;;
esac
