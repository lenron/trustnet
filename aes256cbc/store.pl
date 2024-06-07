#!/usr/bin/perl
use strict;
use warnings;
use cPanelUserConfig;

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
	my $hash_ref = $json->decode($q->param('POSTDATA'));
	my $fingerprint = $hash_ref->{fingerprint};
	my $data = $hash_ref->{data};

	# check for only hex and b58 chars
	# check that SQL returned a response of success

	# First try to create new record. If that fails, modify the existing one.
	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("INSERT INTO $db_table (fingerprint, data) VALUES (?, ?)", undef, $fingerprint, $data);
	# undef return indicates we need to modify the record instead.
	if(not defined $response){
		$dbh->do("UPDATE $db_table SET data=? WHERE fingerprint='$fingerprint'", undef, $data) or die $dbh->errstr;
	}
	$dbh->disconnect();

	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename) or die;
	print $fh "fingerprint: $fingerprint\n";
	print $fh "data: $data\n";

	# Notify of success or failure
	print $q->header();
	print '{"response":"3"}';;
}



=pod
# testing - print fingerprints
	# ASC for ascending, DESC for descending
	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
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

	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
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

	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
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







