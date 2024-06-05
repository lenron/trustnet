#!/usr/bin/perl
use strict;
use warnings;

use DBI;

# Manually set up username/password first (sandbox side)
#my $db_username = 'qrconnect';
#my $db_pw = 'testqrconnect';
#my $db_name = 'chatdance';
#my $db_table_chat_rooms = 'chat_rooms';
#my $db_table_chat_messages = 'chat_messages';
#my $db_table_contact_messages = 'contact_messages';

# Set SQL server/production variables
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';
my $db_table_obf = 'obfuscation';

# Create database
my $dbh = DBI->connect('dbi:mysql:', $db_username, $db_pw);
$dbh->do("CREATE DATABASE IF NOT EXISTS $db_name");
$dbh->disconnect;

$dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
# Create table to hold URL and fisher user data
$dbh->do("CREATE TABLE IF NOT EXISTS $db_table_obf (fingerprint VARCHAR(64), data VARCHAR(1000), PRIMARY KEY(fingerprint) )"); 

$dbh->disconnect;



