#!/usr/bin/env perl
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

#my $test = '{"fingerprint":"8774e15f162f4e3a8f03bc7d4c5845bf9bee9bc9c4155802366f90ae92b47c90","data":"KssGAKaFZxjaew5CyT3A1ik8FvnPh3WBpsthTc5za9hvLt7dgcDW1Cvm6M7PwpGDQqzWvzUat9Dtx38jUKgKbWEf9GjRFygdQV9wvzDpH6CQDobfCeUf6AgQ3n2vZX9jt3Shu4pWpXhkta9fqnMso9qttioCs5T1YEW58XB5fXqNHFmXLoxSbFVbud8qF3FAZcC4WLaWWbc4cHPD5XK2NauVpkbtbKGwsanxbkx88GYxsksqGrukCVR9HgYgrp8GXsbWVJ5RbTrZipLsnjXeru5ZKUA5DZJDVucWbeEgBemYj8qtfBTDSyr7egzxQMLPkdncEWWMLee7Y6w1rfMwE9DeFwpTYaf1FKAxPFxaoAVPF5SDmf5GhAmSgbEkvTeyrq7iobWCTe1FbgsNN3RSJEqKF9X8npLH2hUXXwE3QYdUHpqUqaa6jkJmv7zvRWGbVqXnxQ5iRgrUwcUULSJA5eXZVd4iXmQ1KMYy9pHJPyhJneU34sPTUwcUt666SWfbcDqa6RzxhKNCpAXv8hmLqFVUzfZzjGXMBnMSPoihyandTU4pj1sPKfaS15ecw78C5AxKKVV5CkULyXhMcepjKXUUJGYUfWF94FxQzfgBirRCSuk2UGw9LViKgeqNc8tnkne97wSY3QT4UASQs6cJGxe2e4mD8ANy31HiiuY3tnYEwm2h29PUaY5vXJVmZqnNBYoMdCszDa2u1UMhYJdwg4phTVHK8TqjjP8tKTk2Bby8k7cg6mP3BCfBJtNp1yciPF54eMyrLgbBzDCoU4WFC6T7AWF4R3HN4gHzRNeJUai8DfQK44QewqustQA7k4WCEfzE4XRU1yi9w86GByHA3DKrfUo7UxEimy4hTRpwX3X1XAE5oumkcdaVnrKDvUJ18w4qpDWo7Z6USoWRc1HsovGEaYZYqcTTes8CGmCy6rBSPgxbZJrWd8DSZLyReL2wiyNnaEGRbJGjoNmatr2nG1CGZFi4NKbGEaME62BQ"}';
	# Decode to hash ref to extract fingerprint
	my $hash_ref = $json->decode($q->param('POSTDATA'));
#	my $hash_ref = $json->decode($test);
	my $fingerprint = $hash_ref->{fingerprint};

	# Get current time for log.
	my $t = localtime;
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = './log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "DELETE\n";
	print $fh "$time\n";
	print $fh "fingerprint: $fingerprint\n";

	# Match exactly 64 hex chars, (i)gnoring case.      Match exactly 1000 base58 chars.
	##if( !($fingerprint =~ /^[0-9a-f]{64}$/i) ){
		#print $q->header();
		## qq{} is a standin for double quotes, used here so we can pass the dub quote char to print.
		#print qq{{"response":"0"}};
		#exit 0;
	#}

	# First try to create new record. If that fails, modify the existing one.
	my $dbh = DBI->connect("dbi:mysql:$db_name", $db_username, $db_pw);
	my $response = $dbh->do("DELETE FROM $db_table WHERE fingerprint=?", undef, $fingerprint);
	$dbh->disconnect();

	# Notify of success or failure
	print $q->header();
	print qq{{"response":"$response"}};
}



#exit 0;





