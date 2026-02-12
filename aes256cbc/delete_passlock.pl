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

#if ($q->param){
#my $test = '{"browser_id":"f6285edb-c048-45c7-9a74-9ddc4c7440be"}';

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught some data.
	my $filename = './logs/passlock_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "\n\nDELETE\n";
	print $fh "$time\n";

	my $postdata = $q->param('POSTDATA');
	print $fh "POSTDATA: $postdata\n";
	# Decode to hash ref to extract browser_id and passlock
	my $hash_ref = $json->decode(scalar $q->param('POSTDATA'));
	#my $hash_ref = $json->decode($test);

	# Extract values from json-like object (whatever it is).
	my $browser_id = $hash_ref->{browser_id};

	print $fh "browser_id: $browser_id\n";
exit(0);
	# Try checking for existence first because mariadb versions work differently.
	#my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#my $response = $dbh->do("INSERT INTO $db_table (browser_id, passlock) VALUES (?, ?)", undef, $browser_id, $passlock);
	#print $fh "response after INSERT: $response\n";

	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("DELETE FROM $db_table WHERE browser_id=?", undef, $browser_id);
	print $fh "response after INSERT: $response\n";
	#$dbh->disconnect();

	print $q->header();
	print qq{{"response":"$response"}};
#}


	#my $input = scalar $q->param('POSTDATA');
	#my $hash_ref = $json->decode($input);


	#my $try_response = $dbh->do("SELECT * FROM obfuscation WHERE browser_id=?", undef, $browser_id);

	#print $fh "1 if a record found, 0 if needs new record: $try_response\n";
	#my $response = 'init';
	#if( $try_response == 1 || $try_response eq '1'){
		# found a record, use update
		#$response = $dbh->do("UPDATE $db_table SET passlock=? WHERE browser_id=?", undef, $passlock, $browser_id);
		#print $fh "response after UPDATE: $response\n";
	#}else{
		# no record found, use insert
		#$response = $dbh->do("INSERT INTO $db_table (browser_id, passlock) VALUES (?, ?)", undef, $browser_id, $passlock);
		#print $fh "response after INSERT: $response\n";
	#}
	#print $q->header();
	#print qq{{"response":"$response"}};








