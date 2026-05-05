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
my $access_failures_today_table = 'access_failures_today_per_ip';

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

	# Match exactly 43 hex chars.
	if (!($fingerprint =~ /^[a-zA-Z0-9\+\/]{43}$/)){
		# Return fail if data isn't in the proper form.
		print $q->header();
		print qq{{"access_response":"FINGERPRINT_INVALID"}};
		exit 0;
	}

	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	# First check if we need to disallow the Access attempt.
	my $access_fails_today = get_access_fails_today($dbh, $ip);
	print $fh "access_fails_today: $access_fails_today\n";
	if ($access_fails_today >= 100){
		# Continue to record failures.
		$dbh->do("INSERT INTO $access_failures_today_table (ip, access_failures_today) VALUES (?, 1) ON DUPLICATE KEY UPDATE access_failures_today = access_failures_today + 1;", undef, $ip);
		print $q->header();
		print qq{{"access_response":"TOO_MANY_ACCESS_FAILURES"}};
	} else {
		my $access_response = get_data_at_fingerprint($dbh, $fingerprint);
		print $fh "get_data_at_fingerprint response: $access_response\n";
		# Increment failure count on fail.
		if ($access_response eq "NOT_FOUND"){
			# Store new ip or increment failure count for existing.
			$dbh->do("INSERT INTO $access_failures_today_table (ip, access_failures_today) VALUES (?, 1) ON DUPLICATE KEY UPDATE access_failures_today = access_failures_today + 1;", undef, $ip);
		}
		# Return data to client.
		print $q->header();
		print qq{{"access_response":"$access_response"}};
	}
}


# Get the data stored at fingerprint location.
# Will return NOT_FOUND if record doesn't exist.
sub get_access_fails_today {
	my $dbh = shift;
	my $ip = shift;
	my $query = "SELECT access_failures_today FROM $access_failures_today_table WHERE ip = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($ip);
	# If data isn't found at $fingerprint, this variable won't get overwritten.
	my $access_fails = 'FAILED_TO_GET_COUNT_FOR_ACCESS_FAILURES';
	while (my $row = $sth->fetchrow_hashref){
		$access_fails = $row->{access_failures_today};
	}   
	return $access_fails;
} 

# Get the data stored at fingerprint location.
# Will return NOT_FOUND if record doesn't exist.
sub get_data_at_fingerprint {
	my $dbh = shift;
	my $fingerprint = shift;
	my $query = "SELECT data FROM $db_table WHERE fingerprint = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($fingerprint);
	my $data = 'NOT_FOUND';
	while (my $row = $sth->fetchrow_hashref){
		$data = $row->{data};
	}   
	return $data;
} 





