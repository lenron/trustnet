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
my $db_table = 'obfuscation';
my $db_name = 'chatriwe_obf';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	my $fingerprint = $hash_ref->{fingerprint};

	add_log_message_with_time_and_ip("DELETE");
	add_log_message("fingerprint: $fingerprint");

	# Connect to database. Functionality is handled by the database handle $dbh.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("DELETE FROM $db_table WHERE fingerprint=?", undef, $fingerprint);
	$dbh->disconnect();

	# Notify of success or failure
	print $q->header();
	print qq{{"response":"$response"}};
}







