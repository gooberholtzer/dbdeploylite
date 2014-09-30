#dbdeploylite
============

A bash-only implementation of dbdeploy for sqlite.

This project roughly follows the implementation of dbdeploy but is implemented to only require basic bash scripting.  It was specifically implemented to work with an embedded environment with busybox utilities present.  It has also been tested and found to work on OS X 10.9.4. 

DBDeploy is a utility found at http://dbdeploy.com.  The basic documentation should provide a proper context to the way dbdeploylite works.  DBDeploy (and dbdeploylite) provide a controlled mechanism for migrating database schemas (sqlite only in this case) while preserving the data in the database instance.  "Delta" SQL scripts are placed in a single directory and are named using a prefixed number that must increase with the addition of new scripts.  For example the first script can be named 1yourdescrption.sql and the next can be 2yourotherdescription.sql.  Zero padding is supported, so a script named 05.sql will be correctly run after 4.sql.  The first script MUST be numbered 1 or greater (it cannot be 0, e.g. 0_will_not_run.sql).

When the dbdeploylite.sh utility is run, it looks in a changelog table of the target database to see which scripts have already been run and then runs any additional scripts that are present in order starting at the first one not yet run.  The changelog table is updated to show that all the scripts have been applied.  As a result, running dbdeploylite on a database brings that database from its current state up to the present by running any un-applied delta scripts to the database.  Running dbdeploylite a second time on a database has no effect unless additional scripts (that are numbered higher than the previous highest script run) have been saved to the script dirctory before re-running the utility.
## The changelog Table
For a database to be managed by dbdeploylite it must include the changelog table. This table can be added to a database using the script that is also packaged with the project.  Add the table as follows:

sqlite3 yourdatabase < create_changelog_table.sql

## To Run dbdeploylite
To run dbdeploylite use the following syntax:

./dbdeploylite <database file> <directory with scripts> 

## Try the Unit Tests First
There are simple unit tests included in the repo.  After cloning the project, just run ./testrunner.sh to confirm that all the tests pass.
