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
	# test or otherwise
	my $dbase_key = $hash_ref->{dbase_key};

	# Start with a test dbase.
	#my $dbase_key = "test";
	my $dbase;
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $query = "SELECT dbase FROM $db_table WHERE name = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($dbase_key);
	while ( my $row = $sth->fetchrow_hashref ){
		$dbase = $row->{dbase};
	}
	$dbh->disconnect();

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "OFFLINE_DBASE GET\n";
	print $fh "$time\n";

	# Notify of success or failure
	print $q->header();
	print qq{{"dbase":"$dbase"}};
}










