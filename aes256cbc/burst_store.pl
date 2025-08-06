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
	#print $fh "fingerprint: $fingerprint\n";
	#print $fh "data: $data\n";
	#foreach my $record (@{$hash_ref->{records}}) {
	  #print $fh "fingerprint: $record->{fingerprint}\ndata: $record->{data}\n\n";
	#}
	#print $q->header();
	#print qq{{"response":"test success"}};
	#exit 0;
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
		# Loop through dummy data until we find a valid fingerprint.
		if( $go_flag == 1 || ($total_records - $num_dummy_data) == 1 ){
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
		# Case where all dummy data except for 1 single good record at the end. First burst!
			#$response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $record->{fingerprint}, $record->{data}, $ip);
			#$num_new_records++;
		#}elsif( $go_flag == 0 ){
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



=pod
	if($test_fingerprint =~ /^[0-9a-f]{64}$/i){
		print "fingerprint matched\n";
	}else{
		print "fingerprint not matched\n";
	}

	if($test_data =~ /^[1-9A-HJ-NP-Za-km-z]{1000}$/){
		print "data matched\n";
	}else{
		print "data not matched\n";
	}

# testing - print fingerprints
	# ASC for ascending, DESC for descending
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $query = "SELECT fingerprint FROM $db_table";
	#my $query = "SELECT sender, timestamp, content, screenname FROM $db_table_chat_messages WHERE chat_id=$chat_id ORDER BY timestamp ASC";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	# Fill chat message array with rows containing an internal hash
	my @chat_data_from_sql;
	my $internal_hash;
	while( my $row = $sth->fetchrow_hashref ){
		print "fp: $row->{fingerprint}\n";

	}

	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#$dbh->do("UPDATE $db_table_misc_data SET name=?, value=? WHERE name='$name'", undef, $name, $value);
#"INSERT INTO $db_table_contact_messages (ip, message) VALUES (?, ?)", undef, $ip, $message
	$dbh->do("INSERT INTO $db_table (fingerprint, data) VALUES (?, ?)", undef, $value, $data);
	$dbh->disconnect();

#save sub core
if ($q->param){

	# Decode to hash ref to extract user_id and subscription
	my $hash_ref = $json->decode($q->param('POSTDATA'));
	my $user_id = $hash_ref->{id};
	my $subscription = $hash_ref->{sub};

	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#$dbh->do("UPDATE $db_table_misc_data SET name=?, value=? WHERE name='$name'", undef, $name, $value);
	$dbh->do("UPDATE $db_table_user_id SET subscription=? WHERE user_id='$user_id'", undef, $subscription);
	$dbh->disconnect();

	# Notify of success or failure
	print $q->header();
	print '{"message":"success"}';;
}

#logging
	# log user_id, message, and subscription for each time this 
	my $filename = './log.txt';
	open(my $fh, '>>', $filename) or die;
	print $fh "browser: $browser\n";
	print $fh "time: $time\n";
	print $fh "user_id: $user_id\n";
	print $fh "message: $msg\n";

=cut







