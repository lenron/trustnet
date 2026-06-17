#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;
require "/usr/local/apache2/htdocs/backend-perl-scripts/pgolib.pl";

# Create CGI and json objects.
my $q = CGI->new;
my $json = JSON->new;
# Set SQL variables
my $db_table = 'obfuscation';
my $db_name = 'chatriwe_obf';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');

if ($q->param){

	# records: array of hashes
	my $hash_ref = $json->decode(scalar $q->param('POSTDATA'));

	# Get user ip.
	my $ip = $ENV{REMOTE_ADDR};

	add_log_message_with_time_and_ip("BURST STORE");

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
		if( $go_flag == 1 ){
			# Now we can try inserting first. Will return empty if the record already exists.
			#$response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $record->{fingerprint}, $record->{data}, $ip);
			#print $fh "checking fingerprint after edge found: $record->{fingerprint}\n";
			my $try_response = $dbh->do("SELECT * FROM obfuscation WHERE fingerprint=?", undef, $record->{fingerprint});
			#print $fh "try_response: $try_response\n";
			if( $try_response == 1){
				#print $fh "Record exists update it!  ";
				# Record exists, update it.
				my $response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $record->{data}, $ip, $record->{fingerprint}) or die $dbh->errstr;
				#print $fh "response: $response\n";
				$num_updated_records++;
			}else{
				#print $fh "Record NO exists INSERT it!  ";
				# Record didn't exist, increment count.
				my $response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $record->{fingerprint}, $record->{data}, $ip);
				#print $fh "response: $response\n";
				$num_new_records++;
			}
		# Loop through dummy data until we find a valid fingerprint.
		}else{

			# Does the record exist? will return 1 if yes, 0 if no.
			my $try_response = $dbh->do("SELECT * FROM obfuscation WHERE fingerprint=?", undef, $record->{fingerprint});
			if($try_response == 1){
				# Record exists: update it.
				my $resp = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $record->{data}, $ip, $record->{fingerprint}) or die $dbh->errstr;
				$go_flag = 1;
				$num_updated_records++;
			}else{
				# Does not exist: just increment.
				# The number of dummy data should equal number of invalid fingerprints.
				$num_dummy_data++;
			}
			#$response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $record->{data}, $ip, $record->{fingerprint}) or die $dbh->errstr;
			# Switch to good data if we found updatable edge.
			#if($response == 1){
			#$go_flag = 1;
			#$num_updated_records++;
			#}else{
			## The number of dummy data should equal number of invalid fingerprints.
			#$num_dummy_data++;
			#}
		}
	}

	$dbh->disconnect();
	# Notify of success or failure
	print $q->header();
	print qq{{"response":"success"}};
}









