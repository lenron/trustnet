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

if ($q->param){

	# Decode to hash ref to extract fingerprint and data
	my $hash_ref = $json->decode(scalar $q->param('POSTDATA'));
	my $fingerprint = $hash_ref->{fingerprint};
	#my $fingerprint = "de81a20f681e29f6f6cbbe2bb583f37a5e7c76ff446a7dad43204d54bcac9345";

	# Get user ip.
	my $ip = $ENV{REMOTE_ADDR};
	#my $ip = "1.1.1.1";


	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "LOAD\n";
	print $fh "$time\n";
	print $fh "$ip\n";
	print $fh "fingerprint: $fingerprint\n";

	# Return fail if data isn't in the proper form.
	# Match exactly 64 hex chars, (i)gnoring case.
	if( !($fingerprint =~ /^[0-9a-f]{64}$/i) ){
		print $q->header();
		# qq{} is a standin for double quotes, used here so we can pass the dub quote char to print.
		print qq{{"response":"0"}};
		exit 0;
	}

	my $data = '';
	my $upload_flag= '';
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $query = "SELECT data FROM $db_table WHERE fingerprint = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($fingerprint);
	while ( my $row = $sth->fetchrow_hashref ){
		$data = $row->{data};
	}

	print $fh "data: $data\n";

	# 
	print $q->header();
	# Form custom JSON Object
	print qq{{"data":"$data"}};
}








