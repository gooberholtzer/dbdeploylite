#! /bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

SQL_COMMAND_LINE="sqlite3"

#when on will echo the sql executed.
VERBOSE="off"

# Error definitions
SUCCESS=0
ERROR=1

# Helper functions
validateArgumentsAndInit() {
  
  if [ "$1" -eq "2" ] 
  then
    DATABASE_FILE=$2
    DELTA_DIR=$3
    return 0
  fi
}

outputGreen() {
  echo "${GREEN}$1${NOCOLOR}"
}

outputRed() {
  echo "${RED}$1${NOCOLOR}"
}

validateArgumentsAndInit "$#" "$1" "$2"

# ---------------------------------------------------------
# Verify the last deltascript that was applied is correct
# ---------------------------------------------------------
LAST_SCRIPT_EXPECTED=101
LAST_SCRIPT_APPLIED=`$SQL_COMMAND_LINE $DATABASE_FILE "SELECT change_number FROM changelog ORDER BY change_number DESC limit 1;"` 
if [ "$LAST_SCRIPT_APPLIED" -ne "$LAST_SCRIPT_EXPECTED" ] 
  then
    outputRed "VERIFICATION FAIL: Expected last script to be $LAST_SCRIPT_EXPECTED, was $LAST_SCRIPT_APPLIED"
    exit $ERROR
fi

# -----------------------------------------------------------------
# Verify that all the scripts ran by counting the number of rows
# -----------------------------------------------------------------
SQL="SELECT count(*) FROM table1;"
ROW_COUNT_EXPECTED=12
ROW_COUNT_ACTUAL=`$SQL_COMMAND_LINE $DATABASE_FILE "$SQL"` 
if [ "$ROW_COUNT_ACTUAL" -ne "$ROW_COUNT_EXPECTED" ] 
  then
    outputRed "VERIFICATION FAIL: Expected row count: $ROW_COUNT_EXPECTED, actual row count: $ROW_COUNT_ACTUAL. SQL: $SQL"
    exit $ERROR
fi

exit $SUCCESS
