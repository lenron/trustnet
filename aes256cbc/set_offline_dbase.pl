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
my $db_table = 'offline_dbase';
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';

if ($q->param){

	# Decode to hash ref to extract data.
	my $hash_ref = $json->decode($q->param('POSTDATA'));
	my $offline_dbase = $hash_ref->{offline_dbase};
	my $fingerprint = $hash_ref->{fingerprint};

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "OFFLINE_DBASE SET\n";
	print $fh "$time\n";

	# Start with a test dbase.
	#my $fingerprint = "8774e15f162f4e3a8f03bc7d4c5845bf9bee9bc9c4155802366f90ae92b47c90";
	#my $offline_dbase = "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";

	# Match exactly 64 hex chars, (i)gnoring case.      Match exactly 50000 base58 chars.
	if( !($fingerprint =~ /^[0-9a-f]{64}$/i) || !($offline_dbase =~ /^[1-9A-HJ-NP-Za-km-z]+$/) ){
		# Log unsuccessful attempt.
		print $fh "DATA FAILED LENGTH + CHAR TYPE CHECK!\n";
		print $fh "fingerprint: $fingerprint\n";
		# Print header for POST response.
		print $q->header();
		# qq{} is a standin for double quotes, used here so we can pass the dub quote char to print.
		print qq{{"response":"0"}};
		exit 0;
	}
		print $fh "fingerprint: $fingerprint\n";

	## First try to create new record. If that fails, modify the existing one.
	#my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#my $response = $dbh->do("INSERT INTO $db_table (fingerprint, data, upload_flag) VALUES (?, ?, ?)", undef, $fingerprint, $data, $upload_flag);
	## undef return indicates we need to modify the record instead.
	#if(not defined $response){
		#$response = $dbh->do("UPDATE $db_table SET data=?, upload_flag=? WHERE fingerprint=?", undef, $data, $upload_flag, $fingerprint) or die $dbh->errstr;
	#}
	#$dbh->disconnect();


	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("INSERT INTO $db_table (dbase, reference) VALUES (?, ?)", undef, $offline_dbase, $fingerprint);
	# undef return indicates we need to modify the record instead.
	if(not defined $response){
		$response = $dbh->do("UPDATE $db_table SET dbase=? WHERE reference=?", undef, $offline_dbase, $fingerprint) or die $dbh->errstr;
	}
	$dbh->disconnect();

	# Notify of success or failure
	print $q->header();
	print qq{{"response":"$response"}};
}










