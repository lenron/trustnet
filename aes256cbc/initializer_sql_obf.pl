#!/usr/bin/perl
use strict;
use warnings;

#use DBI;

##########################################################
# This script kept mostly as a reference to SQL structure.
##########################################################

# Set username/password (sandbox side)
#my $db_username = 'testuser';
#my $db_pw = 'password';
# Set SQL server/production variables
#my $db_username = 'chatriwe_admin';
#my $db_pw = 'Vuu_fQY1#qH,';
# Database + Table names should be the same
#my $db_name = 'chatriwe_obf';
#my $db_table_obf = 'obfuscation';

# Create database
#my $dbh = DBI->connect('dbi:MariaDB:', $db_username, $db_pw);
#my $dbh = DBI->connect('dbi:mysql:', $db_username, $db_pw);
#$dbh->do("CREATE DATABASE IF NOT EXISTS $db_name");

#$dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
#$dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
# Create table to hold URL and fisher user data
#$dbh->do("CREATE TABLE IF NOT EXISTS $db_table_obf (fingerprint VARCHAR(64), data VARCHAR(1000), ip VARCHAR(16), timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(fingerprint) )"); 

#$dbh->disconnect;



