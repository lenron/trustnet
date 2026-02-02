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
#my $test = '{"fingerprint":"8774e15f162f4e3a8f03bc7d4c5845bf9bee9bc9c4155802366f90ae92b47c90","data":"RsmSMEJ3HPWbEMHeYmczY9RMEF9KsZCQZqeKMmGE5dUi6xrtavmNHV5T3sDgpziinMRNhRr9xJfAbwn36sV7ZUqefjHkUV4AYU13LzTVTwZcosaBJUFXmNzbp7Ta4qVBnqiWCe1vdVVCUBhCjwCFm6HntMj26BETP6x2rQwbd5X7i3YnmFiCy8CtdZLpGebKeBm6b4d22m5hr52pWxtGApZAuAhc6LtBNKFEP5Etv3yawn8sffwfbaK4wFRiAgpt4PmGKWGwqdSzpDTEi98r6BeHE2Ja67etiQUTjnmvfByGdwVkwsRumx8AV2ibZQ1rfyxMihACAu1qeX5YaMEUctbAm2BRYDMZyixSw49gZEUsX2AS9HzXW1PY2oFkkyhHtXHjQjy923eXanQ6QfFMUsnDdLVpSQ6cszgnuYakquc42qKbzR1cDbvtnU5qeQ9jYSJjcxHmSrF5GEtGsipW882eWztMZRtHcXoZVNfwN5gxv2NQYTbYBXpAx42t5NCcokPzLw9ifgiK5Sa2AxbFFF28u8MSERU67TE2fRwy2whYgWySsAoywpFEKkLoHFygaWNWXjua6Xr73UMY2WyTtU5MB1rCpAvUgeQwY441sZMTXqg5xydUuERzaSt5XALuRCufDzaE2XnY8zgTDPC59gDZPQuYUhz7bjFVPo7HE1maRgePHCu4WWKHuwbs2enYaHxf6cbBeoRq3ybG5siDYRBSNw1eowCztt6y9KZXWp2TxCrdBU75REg7tNKuyaevwMqK5w5VbCYEQsJewJR8UpqJdpVYQp44Mop8gLZxhYut16Tb5Zv7UdgByoPELF5Wdfphjj1DKcU2CGytfQLt5Wb38AxMygvPLiuWD1smdWkgMx4urAoSftSHa2YMngmjxVJKRdAHVYnoNcYLm9u2bp2jSkoci1jFbhya1HtB1AF7LPSL7XArDbTcjRsbdUbo4RUBxcQg9kvMricPDsU4fnfm3NGTEXzzb3burMm3"}';
#
#

	# Get user ip.
	my $ip = $ENV{REMOTE_ADDR};
	#my $ip = "1.1.1.1";

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "\n\nSTORE\n";
	print $fh "$time\n";
	print $fh "$ip\n";

	# Decode to hash ref to extract fingerprint and data
	#my $hash_ref = $json->decode(scalar $q->param('POSTDATA'));
	#my $hash_ref = $json->decode($test);
	#
	my $input = scalar $q->param('POSTDATA');
	my $hash_ref = $json->decode($input);
	my $fingerprint = $hash_ref->{fingerprint};
	my $data = $hash_ref->{data};

	print $fh "json input:\n $input\n\n";
	print $fh "fingerprint: $fingerprint\n";
	print $fh "data: $data\n";

	# Return fail if data isn't in the proper form.
	# Match exactly 64 hex chars, (i)gnoring case.      Match exactly 1000 base58 chars.
	#if( !($fingerprint =~ /^[0-9a-f]{64}$/i) || !($data =~ /^[1-9A-HJ-NP-Za-km-z]{1000}$/) ){
	if( !($fingerprint =~ /^[0-9a-f]{64}$/i) || !($data =~ /^[a-zA-Z0-9\+\/]{1000}$/) ){
		print $q->header();
		# qq{} is a standin for double quotes, used here so we can pass the dub quote char to print.
		print qq{{"response":"0"}};
		exit 0;
	}

	# Try checking for existence first because mariadb versions work differently.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	my $try_response = $dbh->do("SELECT * FROM obfuscation WHERE fingerprint=?", undef, $fingerprint);

	print $fh "1 if a record found, 0 if needs new record: $try_response\n";
	my $response = 'init';
	if( $try_response == 1 || $try_response eq '1'){
		# found a record, use update
		$response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $data, $ip, $fingerprint);
		print $fh "response after UPDATE: $response\n";
	}else{
		# no record found, use insert
		$response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $fingerprint, $data, $ip);
		print $fh "response after INSERT: $response\n";
	}
	print $q->header();
	print qq{{"response":"$response"}};



}


	# First try to create new record. If that fails, modify the existing one.
	#my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#my $response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $fingerprint, $data, $ip);
	#my $response = $dbh->do("UPDATE $db_table SET data=?, ip=? WHERE fingerprint=?", undef, $data, $ip, $fingerprint);
	#print $fh "response after UPDATE: $response\n";
	#$dbh->disconnect();

	# undef return indicates we need to modify the record instead.
	# 0E0 means 0 rows effected.
	#my $insert_response = "init";
	#if(not defined $response || $response eq '0E0'){
	#$dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	#$insert_response = $dbh->do("INSERT INTO $db_table (fingerprint, data, ip) VALUES (?, ?, ?)", undef, $fingerprint, $data, $ip);
	#$dbh->disconnect();
	#}
	#print $fh "response after INSERT: $insert_response\n";

	# Notify of success or failure
	#print $q->header();
	#print qq{{"response":"$response"}};
	#}







