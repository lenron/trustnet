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

	# records: array of hashes
	my $hash_ref = $json->decode($q->param('POSTDATA'));

	# Get user ip.
	my $ip = $ENV{REMOTE_ADDR};

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './burst_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "STORE BURST\n";
	print $fh "$time\n";
	print $fh "$ip\n";

	# Gather data for a report that isn't gigantic.
	my $num_dummy_data = 0;
	my $num_new_records = 0;
	my $num_updated_records = 0;
	my $num_records = 0;
	my $go_flag = 0;
	my $response;
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $total_records = scalar @{$hash_ref->{records}};
	foreach my $record (@{$hash_ref->{records}}) {
		# Count number of total records.
		$num_records++;
		#if( $go_flag == 1 || ($total_records - $num_dummy_data) == 1 ){
		if( $go_flag == 1 ){
			# Now we can try inserting first. Will return empty if the record already exists.
			$response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $record->{fingerprint}, $record->{data}, $ip);
			if(not defined $response){
				# Record exists, update it.
				$response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $record->{data}, $ip, $record->{fingerprint}) or die $dbh->errstr;
				$num_updated_records++;
			}else{
				# Record didn't exist, increment count.
				$num_new_records++;
			}
		# Loop through dummy data until we find a valid fingerprint.
		}else{
			$response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $record->{data}, $ip, $record->{fingerprint}) or die $dbh->errstr;
			# Switch to good data if we found updateable edge.
			if($response == 1){
				$go_flag = 1;
				$num_updated_records++;
			}else{
				# The number of dummy data should equal number of invalid fingerprints.
				$num_dummy_data++;
			}
		}
	}

	$dbh->disconnect();
	print $fh "total_records: $total_records\n";
	print $fh "num_records, counted: $num_records\n";
	print $fh "num_updated_records: $num_updated_records\n";
	print $fh "num_dummy_data: $num_dummy_data\n";
	print $fh "num_new_records: $num_new_records\n\n";
	# Notify of success or failure
	print $q->header();
	print qq{{"response":"success"}};
}









