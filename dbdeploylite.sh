#! /bin/sh

SQL_COMMAND_LINE="sqlite3"

#temp file definitions...
UNORDEREDFILES_FILE="unordered.tmp.txt"
ORDEREDFILES_FILE="ordered.tmp.txt"
QUERY_ERRORS_FILE="sql.query.error.tmp.txt"
DELTA_DIR_FILES="files_in_delta_dir.tmp.txt"
DUPLICATE_DETECTION_FILE="dups.tmp.txt"

#when on will echo the sql executed.
VERBOSE="off"

# Error definitions
SUCCESS=0
ERROR_CHANGE_LOG_TABLE_MISSING=1
ERROR_NO_DELTAS_FOUND=2
ERROR_DATABASE_NOT_FOUND=3
ERROR_DUPLICATE_SCRIPT_NUMBER=4
ERROR_IN_SQL_QUERY=5

files="[1-9]*.sql"
regex="([0-9]+).*"

printSyntax() {
  echo 'dbeploylite [-v] <delta directory> <path to database file>';
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

cleanupTempFiles() {

 if [ -e $UNORDEREDFILES_FILE ]
 then
   rm $UNORDEREDFILES_FILE
 fi
 
 if [ -e $ORDEREDFILES_FILE ]
 then
   rm $ORDEREDFILES_FILE
 fi

 if [ -e $QUERY_ERRORS_FILE ]
 then
   rm $QUERY_ERRORS_FILE 
 fi

 if [ -e aggregate_deltascript_file.sql ]
 then
   rm aggregate_deltascript_file.sql
 fi

 if [ -e $DELTA_DIR_FILES ]
 then
   rm $DELTA_DIR_FILES
 fi

 if [ -e $DUPLICATE_DETECTION_FILE ]
 then
   rm $DUPLICATE_DETECTION_FILE
 fi

}

checkDependencies() {

  if [[ -z `which $SQL_COMMAND_LINE` ]]; then
    echo "ERROR: $SQL_COMMAND_LINE not found, install it or put it in your path to continue."
    exit -1
  fi

  if [[ ! -w . ]]; then
    echo "ERROR: Current user does not have needed write permission in the PWD used when running dbdelpoylite."
    exit -1
  fi
}

getLastDeltaScriptNumber() {
  LAST_SCRIPT_APPLIED=`$SQL_COMMAND_LINE $DATABASE_FILE "SELECT change_number FROM changelog ORDER BY change_number DESC limit 1;"` 

  if [ -z $LAST_SCRIPT_APPLIED ]; then
    LAST_SCRIPT_APPLIED=0
  fi

  return $LAST_SCRIPT_APPLIED
}

validateArgumentsAndInit "$#" "$1" "$2" "$3"

checkDependencies

cleanupTempFiles

echo "Applying delta scripts in $2"

# check that the database is there
if [ ! -e "$DATABASE_FILE" ]; then
  echo "ERROR($ERROR_DATABASE_NOT_FOUND): The database $1 not found."
  cleanupTempFiles
  exit $ERROR_DATABASE_NOT_FOUND
fi

#check that the database has a changelog table...
NUM_CHANGELOG_ROWS=$($SQL_COMMAND_LINE $DATABASE_FILE "select count(*) from changelog;" 2> /dev/null )
if [ -z $NUM_CHANGELOG_ROWS ]; then
  echo "ERROR($ERROR_CHANGE_LOG_TABLE_MISSING): The $DATABASE_FILE database does not have the required changelog table."
  cleanupTempFiles
  exit $ERROR_CHANGE_LOG_TABLE_MISSING
fi

# check if any delta scripts
NUM_DELTAS=`find "$DELTA_DIR" -name "$files"  | wc -l`
if [ "$NUM_DELTAS" -eq 0 ]; then
  echo "ERROR($ERROR_NO_DELTAS_FOUND): There are no delta scripts to process."
  cleanupTempFiles
  exit $ERROR_NO_DELTAS_FOUND
fi

# enumerate and order the delta scripts.
find $DELTA_DIR > "$DELTA_DIR_FILES"
sed -n 's/\(^.*\/\([0-9]*\).*\.sql$\)/\2 \1/p' $DELTA_DIR_FILES > $UNORDEREDFILES_FILE

cat $UNORDEREDFILES_FILE | sort -n > $ORDEREDFILES_FILE

# check that there are no duplicate numbered scripts...
awk '{print $1}' ordered.tmp.txt | uniq -d | head -n 1 > $DUPLICATE_DETECTION_FILE

#report duplicate scripts and exit
if [ -s $DUPLICATE_DETECTION_FILE ]; then
  echo "ERROR($ERROR_DUPLICATE_SCRIPT_NUMBER): Multiple scripts with same order number exist..."
  ls $DELTA_DIR/`cat $DUPLICATE_DETECTION_FILE`[^0-9]*
  cleanupTempFiles
  exit $ERROR_DUPLICATE_SCRIPT_NUMBER
fi

getLastDeltaScriptNumber
echo "Before applying deltas, the last script applied was number: $?"

#build the aggregate delta script with support for transactions
echo '.bail on' > aggregate_deltascript_file.sql 
echo ".echo $VERBOSE" >> aggregate_deltascript_file.sql 
echo 'BEGIN  TRANSACTION;' >> aggregate_deltascript_file.sql

AWK_COMMAND='$1>'"$LAST_SCRIPT_APPLIED"' {
	deltascript=$2
	system( "echo SELECT\\(\\\"" deltascript "\\\"\\)\\; >> aggregate_deltascript_file.sql" )
	system( "cat " deltascript " >> aggregate_deltascript_file.sql" )
	system( "echo INSERT INTO changelog VALUES\\(" $1 ", CURRENT_TIMESTAMP, \\\"n/a\\\", \\\"" deltascript "\\\"\\)\\; >> aggregate_deltascript_file.sql")
	}'

awk "$AWK_COMMAND" "$ORDEREDFILES_FILE"

echo 'COMMIT TRANSACTION;' >> aggregate_deltascript_file.sql 

$SQL_COMMAND_LINE $DATABASE_FILE < aggregate_deltascript_file.sql 2>$QUERY_ERRORS_FILE 

if [ -s "$QUERY_ERRORS_FILE" ]
then
  echo "ERROR($ERROR_IN_SQL_QUERY): SQL Query Error: `cat $QUERY_ERRORS_FILE`"
  cleanupTempFiles
  exit $ERROR_IN_SQL_QUERY
fi

getLastDeltaScriptNumber
echo "After applying deltas, the last script applied was number: $?"

#clean up
cleanupTempFiles
exit $SUCCESS

