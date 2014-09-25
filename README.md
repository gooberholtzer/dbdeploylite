dbdeploylite
============

A bash-only implementation of dbdeploy for sqlite.

This project roughly follows the implementation of dbdeploy but is implemented to only require basic bash scripting.  It was specifically implemented to work with an embedded environment with busybox utilities present.  It has also been tested and found to work on OS X 10.9.4. 

DBDeploy is a utility found at http://dbdeploy.com.  The basic documentation shoudl provide a proper context to the way dbdeploylite works.  DBDeploy (and dbdeploylite) provide a controlled mecahnism for migrating database schemas (sqlite only in this case) while preserving the data in the database instance.  Updates SQL scripts are placed in a single directory and are named using a prefixed number that must increase with the addition of new scripts.  For example the first script is named 1<your descrption>.sql and the next would be 2<your other description>.sql.

When the dbdeploylite.sh utility is run, it looks in a changelog table of the target database to see which scripts have already been run and then runs any additional scripts that are present in oder starting at the first one not yet run.  The changelog table is updated to show that all the scripts have been applied.  As a result, running dbdeploylite on a database brings that database from its current state up to the present by running any un-applied delta scripts to the database.  Running dbdeploylite a second time on a database has no effect unless additional scripts have been saved to the script dirctory before re-running the utility.

For a database to be managed by dbdeploylite it must include the changelog table. This table can be added to a database using the script that is also packaged with the project.  Add the table as follows:

sqlite3 yourdatabase < create_changelog_table.sql

To run dbdeploylite use the following syntax:

./dbdeploylite <database file> <directory with scripts> 


There are simple unit tests included in the repo.  After cloning the project, just run ./runtests.sh to confirm that all the tests pass.


