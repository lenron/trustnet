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

my $test_fingerprint = '942b3dfb68d049de55a45d7b10ed0c62abb0799e38e4463aa8c504d625a841c6'; 
my $test_data = 'Db7Rdw29i19Y57nEnZtFLtkd8G9GDG8zWtkPVtwRA517bnB8D7vgN1RiZ7neF1q8cfT6YGk8e4NLjvwC8DhrcgYN5PL1RXiwjcydzstMZBtn5sqs6D4FgF15cogWS1LARGmFfvmuN4hUaMzHAxe6A5VkLBwXc9rNcC4iHiSZz6acYASKrJ319bCt6wGqx1m3zcJWCqac6SrSKbQCagsuQSQJUSYVMqt8M4QtXZ8HdBock1WUdHR2vdDcvDjRMaRxW1ZhZBJ5eqwQdXsLrRX9514b5CS6Y9muKBJQqXUb1p8fdwYm2BjLmJQjNXoxozLtJ5Q4kMEvYPWxFKcY8hjiLrk2BEF1ivG3bPFs6zwawS2QvryEZWdt52BttGU4qaAxoMFRnSAWqgyJaPt35MGNeFw13BjcKpgUVJpfjYiJ7VoHh1kUcUVN9pty8jYyZ4hBqn5c256v3QBnqpNiMnzmtoiHei3881aBbCk5V61dTxTKs31daxF3gyKP1enKPc5yZfpPadyUTJZUaRNLJKoxT9yb8JraG7t6nCPe63Qkg9KnN8MYHbJmx5QeBFiPy1qJPqzEevsSyaQRNupp6vpUCgPzuLoCigkrLkdiDnmYxS5dB5S2HwAzCR8wQhyY3AMs5g6ZLwK7q5F75Ldxw4cGTYLg81uJzQUB5WYJvztkFx5rhCPUbjXb99JtLMbQUAWanCU26LVTM5mssRm7Sf1uCdcWXqe7JfpiWP8Bv8LQC7F2KAMeURwQafUS6KSof47haPN9S4s8JZc3JYsTxzBaT2uGB89XexCvKnqrYQbucFpnJzMVgoQ7KcFYvwkJ937kfxUD2LQ64GdQtkMtZLiCs79zMidKN9zkhauxrjpz65ckfYmqfu11KLAjZXd4AmoB3zQV4CLZMTYrToJ33FhcqAKtv3AfQ1fJriUaCsUmZaTM8wUHJe6FpTmboiGaH2bA1ziTEVrnuBzbnME9D98GHQgavkKxFxmhY3MoZzdz';

if ($q->param){

	# Decode to hash ref to extract fingerprint and data
	my $hash_ref = $json->decode($q->param('POSTDATA'));
	my $fingerprint = $hash_ref->{fingerprint};
	my $data = $hash_ref->{data};

	# check for only hex and b58 chars
	# check that SQL returned a response of success

	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
	$dbh->do("INSERT INTO $db_table (fingerprint, data) VALUES (?, ?)", undef, $fingerprint, $data);
	$dbh->disconnect();

	# If log exists, we know q->param caught data
	my $filename = './log.txt';
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







