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
my $db_name = 'chatriwe_obf';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){

	# Get current time for log.
	my $t = localtime;
	# Make time format human readable.
	my $time = $t->strftime();
	# If log exists, we know q->param caught some data.
	my $filename = '/usr/local/apache2/logs/passlock_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "\nEXTEND\n";
	print $fh "$time\n";

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	my $browser_id = $hash_ref->{browser_id};

	print $fh "browser_id: $browser_id\n";

	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("UPDATE $db_table SET timestamp = CURRENT_TIMESTAMP WHERE browser_id = ?", undef, $browser_id);
	print $fh "response after UPDATE: $response\n";
	# HTTP POST response requires a header.
	print $q->header();
	print qq{{"response":"$response"}};
}



sub get_first_line{
	my $location = shift;
	open my $first_line_fh, '<', $location or die "Cannot read server type from file: $!";
	# Read in first line. Should only be 1 line in this file.
	my $first_line= <$first_line_fh>;
	close $first_line_fh;
	chomp($first_line); # Remove newline.
	return $first_line;
}





