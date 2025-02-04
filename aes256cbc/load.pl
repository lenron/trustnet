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
	my $hash_ref = $json->decode($q->param('POSTDATA'));
	my $fingerprint = $hash_ref->{fingerprint};

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
	my $query = "SELECT data, upload_flag FROM $db_table WHERE fingerprint = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($fingerprint);
	while ( my $row = $sth->fetchrow_hashref ){
		$data = $row->{data};
		$upload_flag = $row->{upload_flag};
	}

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "LOAD\n";
	print $fh "$time\n";
	print $fh "fingerprint: $fingerprint\n";
	print $fh "data: $data\n";
	print $fh "upload_flag: $upload_flag\n\n";

	# 
	print $q->header();
	#print qq{{"response":"$data"}};
	print qq{{"data":"$data","upload_flag":"$upload_flag"}};
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







