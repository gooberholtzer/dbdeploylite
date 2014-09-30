#! /bin/sh

SQL_COMMAND_LINE="sqlite3"

RED='\033[0;31m'
GREEN='\033[0;32m'
NOCOLOR='\033[0m'

# Error definitions
SUCCESS=0
ERROR_CHANGE_LOG_TABLE_MISSING=1
ERROR_NO_DELTAS_FOUND=2
ERROR_DATABASE_NOT_FOUND=3
ERROR_DUPLICATE_SCRIPT_NUMBER=4
ERROR_IN_SQL_QUERY=5

VERBOSE="off"

outputGreen() {
  echo "${GREEN}$1${NOCOLOR}"
}

outputRed() {
  echo "${RED}$1${NOCOLOR}"
}

validateArgumentsAndInit() {
  
  if [ "$1" -eq "2" ] 
  then
    DATABASE_FILE=$2
    DELTA_DIR=$3
    return 0
  fi

  if [ "$1" -eq "3" ] 
  then
    if [ "$2" != "-v" ]; then
      printSyntax
      exit -1
    fi
    VERBOSE="on" 
    DATABASE_FILE=$3
    DELTA_DIR=$4
    return 0
  fi

  printSyntax
  exit -1
}

