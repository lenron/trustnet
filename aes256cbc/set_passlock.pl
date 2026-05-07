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
my $db_table = 'passlock_table';
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){

	# Get current time for log.
	my $t = localtime;
	# Make time format human readable.
	my $time = $t->strftime();
	# If log exists, we know q->param caught some data.
	my $filename = './logs/passlock_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "\nSET\n";
	print $fh "$time\n";

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	# Extract values from hash.
	my $browser_id = $hash_ref->{browser_id};
	my $passlock = $hash_ref->{passlock};
	# Log data.
	print $fh "browser_id: $browser_id\n";
	print $fh "passlock: $passlock\n";
	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("INSERT INTO $db_table (browser_id, passlock) VALUES (?, ?)", undef, $browser_id, $passlock);

	# Log data.
	print $fh "response after INSERT: $response\n";
	# HTTP POST response requires a header.
	print $q->header();
	print qq{{"response":"$response"}};
}



