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
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');
my $db_name = 'chatriwe_obf';
my $db_table = 'passlock_table';

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){

	add_passlock_log_with_time_and_ip("SET");

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	# Extract values from hash.
	my $browser_id = $hash_ref->{browser_id};
	my $passlock = $hash_ref->{passlock};
	# Log data.
	add_passlock_log("browser_id: $browser_id");
	add_passlock_log("passlock: $passlock");
	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("INSERT INTO $db_table (browser_id, passlock) VALUES (?, ?)", undef, $browser_id, $passlock);

	# HTTP POST response requires a header.
	print $q->header();
	print qq{{"response":"$response"}};
}



