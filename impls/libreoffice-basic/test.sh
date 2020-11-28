src_step="$1"; shift
test_step="$1"; shift

./reset.sh

export NO_COLOR=1
export LIBO_HEADLESS=1
export ENABLE_LOG=0

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
