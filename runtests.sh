#! /bin/sh
RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

BASE_TEST_DIR=./testrun
mkdir -p $BASE_TEST_DIR 

cp -fr ./tests/* $BASE_TEST_DIR 

outputGreen() {
  echo "${GREEN}$1${NOCOLOR}"
}

outputRed() {
  echo "${RED}$1${NOCOLOR}"
}

run_test() {

  ./dbdeploylite.sh $BASE_TEST_DIR/$1/testdb $BASE_TEST_DIR/$1

#snag the return from the call before it gets overwritte  
  RETURNVALUE="$?"

  if [ "$2" -ne "$RETURNVALUE" ] 
      then
        outputRed "FAIL: $1 expected $2 but got $RETURNVALUE"
        exit -1
      else
        outputGreen "PASS: $1"
  fi
}

run_test fails_when_no_deltas_found 2;
run_test fails_when_changelog_missing 1;
run_test fails_on_duplicate_deltas 4;
run_test fails_when_database_not_found 3;
run_test fails_on_error_in_delta 5;
run_test passes_initial_delta_application 0;
run_test passes_subsequent_delta_application 0;

echo "${GREEN}ALL TESTS PASS - Yeah!${NOCOLOR}"

