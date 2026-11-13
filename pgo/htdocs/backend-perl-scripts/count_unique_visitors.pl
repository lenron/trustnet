#!/usr/bin/perl
use strict;
use warnings;

# count_unique_visitors.pl
# Used for DDOs, etc. filter protection for the site.
# Takes a client IP and either stores a new record to MariaDB (if this is their first visit of the day) or increments the IP's count value (if it's not).

use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;
# Use custom library.
require "/usr/local/apache2/htdocs/backend-perl-scripts/pgolib.pl";

# Create CGI and json objects.
my $q = CGI->new;
my $json = JSON->new;
# Set SQL variables
my $db_table = 'obfuscation';
my $db_name = 'chatriwe_obf';
my $unique_visitors_on_date_table = 'unique_visitors_on_date';
my $unique_visitor_ips_today_table = 'unique_visitor_ips_today';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');

# Get user ip.
my $ip = $ENV{REMOTE_ADDR};

#add_log_message("COUNT UNIQUE VISITORS");
my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
my $ip_query_response = check_ip_exists($dbh, $ip);
#add_log_message("ip_query_response: $ip_query_response");
if ($ip_query_response eq "IP_NOT_FOUND") {
	# Add IP to table
	$dbh->do("INSERT INTO $unique_visitor_ips_today_table (ip) VALUES (?);", undef, $ip);
	# Increment count.
	$dbh->do("INSERT INTO $unique_visitors_on_date_table (date_visited, unique_visitors_on_this_date) VALUES (CURRENT_DATE, 1) ON DUPLICATE KEY UPDATE unique_visitors_on_this_date = unique_visitors_on_this_date + 1;", undef);
	print $q->header();
	print qq{{"ip_query_response":"IP_NOT_FOUND"}};
} else {
	print $q->header();
	print qq{{"ip_query_response":"IP_FOUND"}};
}

# Check if a user IP already exists in the daily database, indicating they have already visited today.
sub check_ip_exists {
	my $dbh = shift;
	my $ip = shift;
	# DBI command for returning a single value with SELECT.
	my $ip_query_response = $dbh->selectrow_array("SELECT 1 FROM $unique_visitor_ips_today_table WHERE ip = ?", undef, $ip);
	# Empty retun indicates IP wasn't found.
	if ($ip_query_response eq '') {
		$ip_query_response = 'IP_NOT_FOUND';
	}
	return $ip_query_response;
} 


