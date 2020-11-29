step="$1"

./reset.sh

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
