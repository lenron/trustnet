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

#if ($q->param){
#my $test = '{"fingerprint":"8774e15f162f4e3a8f03bc7d4c5845bf9bee9bc9c4155802366f90ae92b47c90"}';
	# Decode to hash ref to extract fingerprint
	my $input = scalar $q->param('POSTDATA');
	#my $hash_ref = $json->decode(scalar $q->param('POSTDATA'));
	my $hash_ref = $json->decode($input);
	#my $hash_ref = $json->decode($test);
	my $fingerprint = $hash_ref->{fingerprint};

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "DELETE\n";
	print $fh "$time\n";
	print $fh "fingerprint: $fingerprint\n";

	# Match exactly 64 hex chars, (i)gnoring case.      Match exactly 1000 base58 chars.
	##if( !($fingerprint =~ /^[0-9a-f]{64}$/i) ){
		#print $q->header();
		## qq{} is a standin for double quotes, used here so we can pass the dub quote char to print.
		#print qq{{"response":"0"}};
		#exit 0;
	#}

	# First try to create new record. If that fails, modify the existing one.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("DELETE FROM $db_table WHERE fingerprint=?", undef, $fingerprint);
	$dbh->disconnect();
	print $fh "response: $response\n";

	# Notify of success or failure
	print $q->header();
	print qq{{"response":"$response"}};
	#}








