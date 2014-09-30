#! /bin/sh

source ./common.sh

BASE_TEST_DIR=./testrun
mkdir -p $BASE_TEST_DIR 

cp -fr ./tests/* $BASE_TEST_DIR 

run_test() {

  echo "------- BEGIN TEST: $1 -------"

  ./dbdeploylite.sh $BASE_TEST_DIR/$1/testdb $BASE_TEST_DIR/$1

  #snag the return from the call before it gets overwritte  
  RETURNVALUE="$?"

  if [ "$2" -ne "$RETURNVALUE" ] 
      then
        outputRed "FAIL: $1 expected $2 but got $RETURNVALUE"
        exit -1
      else
        if [ -e $BASE_TEST_DIR/$1/verify.sh ]
          then
            $BASE_TEST_DIR/$1/verify.sh $BASE_TEST_DIR/$1/testdb $BASE_TEST_DIR/$1
            RETURNVALUE="$?"
            # All verification scripts must return 0 for success
            if [ "0" -ne "$RETURNVALUE" ] 
              then
                # Verification failure...exit the test suite
                outputRed "FAIL: $1 verification failed"
                exit -1
            fi

        fi

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
run_test passes_with_varying_numeric_prefix_formats 0;

echo "${GREEN}ALL TESTS PASS - Yeah!${NOCOLOR}"

