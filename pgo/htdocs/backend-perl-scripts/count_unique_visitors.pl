#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
use strict;
use warnings;
#use cPanelUserConfig;

use Time::Piece;
use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;

# Create CGI and json objects.
my $q = CGI->new;
my $json = JSON->new;

# Set SQL variables
my $db_table = 'obfuscation';
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';
my $unique_visitors_on_date_table = 'unique_visitors_on_date';
my $unique_visitor_ips_today_table = 'unique_visitor_ips_today';

# Get user ip.
my $ip = $ENV{REMOTE_ADDR};
#my $ip = "1.1.1.1";

# Get current time for log.
my $t = localtime;
# Make time format human readable.
my $time = $t->strftime();
# If log exists, we know q->param caught data.
my $filename = '/usr/local/apache2/logs/log.txt';
# Append to existing file if it exists, create new otherwise.
open(my $fh, '>>', $filename); # or die;
print $fh "COUNT UNIQUE VISITORS\n";
print $fh "$time\n";
print $fh "$ip\n";

my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
my $ip_query_response = check_ip_exists($dbh, $ip);
print $fh "ip_query_response: $ip_query_response\n";
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




