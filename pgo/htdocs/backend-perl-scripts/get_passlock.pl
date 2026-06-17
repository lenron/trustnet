#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;
require "/usr/local/apache2/htdocs/backend-perl-scripts/pgolib.pl";

# Create CGI and json objects.
my $q = CGI->new;
my $json = JSON->new;

# Set SQL variables
my $db_table = 'passlock_table';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');
my $db_name = 'chatriwe_obf';

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	# Extract values from json object decoded hash reference.
	my $browser_id = $hash_ref->{browser_id};

	# Get passlock at browser_id, return.
	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $passlock = $dbh->selectrow_array("SELECT passlock FROM $db_table WHERE browser_id = ?", undef, $browser_id);

	add_passlock_log_with_time_and_ip("GET");
	add_passlock_log("passlock: $passlock");

	# HTTP POST response requires a header.
	print $q->header();
	print qq{{"passlock":"$passlock"}};
}





