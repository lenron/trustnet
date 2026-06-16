#!/usr/bin/perl
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
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');
my $db_name = 'chatriwe_obf';
my $stores_today_per_ip_table = 'stores_today_per_ip';
my $stores_on_date_table = 'stores_on_date';

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){
# Leaving hard to compile test for now.
#my $test = '{"fingerprint":"8774e15f162f4e3a8f03bc7d4c5845bf9bee9bc9c4155802366f90ae92b47c90","data":"RsmSMEJ3HPWbEMHeYmczY9RMEF9KsZCQZqeKMmGE5dUi6xrtavmNHV5T3sDgpziinMRNhRr9xJfAbwn36sV7ZUqefjHkUV4AYU13LzTVTwZcosaBJUFXmNzbp7Ta4qVBnqiWCe1vdVVCUBhCjwCFm6HntMj26BETP6x2rQwbd5X7i3YnmFiCy8CtdZLpGebKeBm6b4d22m5hr52pWxtGApZAuAhc6LtBNKFEP5Etv3yawn8sffwfbaK4wFRiAgpt4PmGKWGwqdSzpDTEi98r6BeHE2Ja67etiQUTjnmvfByGdwVkwsRumx8AV2ibZQ1rfyxMihACAu1qeX5YaMEUctbAm2BRYDMZyixSw49gZEUsX2AS9HzXW1PY2oFkkyhHtXHjQjy923eXanQ6QfFMUsnDdLVpSQ6cszgnuYakquc42qKbzR1cDbvtnU5qeQ9jYSJjcxHmSrF5GEtGsipW882eWztMZRtHcXoZVNfwN5gxv2NQYTbYBXpAx42t5NCcokPzLw9ifgiK5Sa2AxbFFF28u8MSERU67TE2fRwy2whYgWySsAoywpFEKkLoHFygaWNWXjua6Xr73UMY2WyTtU5MB1rCpAvUgeQwY441sZMTXqg5xydUuERzaSt5XALuRCufDzaE2XnY8zgTDPC59gDZPQuYUhz7bjFVPo7HE1maRgePHCu4WWKHuwbs2enYaHxf6cbBeoRq3ybG5siDYRBSNw1eowCztt6y9KZXWp2TxCrdBU75REg7tNKuyaevwMqK5w5VbCYEQsJewJR8UpqJdpVYQp44Mop8gLZxhYut16Tb5Zv7UdgByoPELF5Wdfphjj1DKcU2CGytfQLt5Wb38AxMygvPLiuWD1smdWkgMx4urAoSftSHa2YMngmjxVJKRdAHVYnoNcYLm9u2bp2jSkoci1jFbhya1HtB1AF7LPSL7XArDbTcjRsbdUbo4RUBxcQg9kvMricPDsU4fnfm3NGTEXzzb3burMm3"}';

	# Get user ip.
	my $ip = $ENV{REMOTE_ADDR};
	#my $ip = "1.1.1.1";

	# Get current time for log.
	my $t = localtime;
	# Make time format human readable.
	my $time = $t->strftime();
	# If log exists, we know q->param caught data.
	my $filename = '/usr/local/apache2/logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $fh, '>>', $filename); # or die;
	print $fh "\nSTORE\n";
	print $fh "$time\n";
	print $fh "$ip\n";

	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	my $fingerprint = $hash_ref->{fingerprint};
	my $data = $hash_ref->{data};

	print $fh "json input:\n $posted_data_in_json_object_form\n\n";
	print $fh "fingerprint: $fingerprint\n";
	print $fh "data: $data\n";

	# Store functionality only valid from main site.
	my $server_type_location = "/usr/local/apache2/htdocs/this_server_type.txt";
	open my $type_fh, '<', $server_type_location or die "Cannot read server type from file: $!";
	# Read in first line. Should only be 1 line in this file.
	my $server_type = <$type_fh>;
	close $type_fh;
	chomp($server_type); # Remove newline.
	# Deny entry unless this is a main server. Don't send a HTTP response.
	if ($server_type ne "main") {
		# Log denial due to this not being a 'main' server.
		print $fh "ERROR: STORE DENIED: THIS SERVER ISN'T MAIN!\n";
		exit 0;
	}

	# Match exactly 43 base64 chars.      Match exactly 1024 base64 chars.
	if (!($fingerprint =~ /^[a-zA-Z0-9\+\/]{43}$/) || !($data =~ /^[a-zA-Z0-9\+\/]{1024}$/)){
		# Log denial due to incorrect data format.
		print $fh "ERROR: STORE DENIED due to incorrect data format.\n";
		# Return fail if data isn't in the proper form.
		print $q->header();
		# qq{} is a standin for double quotes, used here so we can pass the double quote char to print.
		print qq{{"store_response":"FINGERPRINT_OR_DATA_INVALID"}};
		exit 0;
	}

	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	# Check hard limit for total stores today.
	my $total_stores_today = get_total_stores_today($dbh, $ip);
	print $fh "Total stores today: $total_stores_today\n";
	if ($total_stores_today >= 50000) {
		# Lock out.
		print $q->header();
		print qq{{"store_response":"TOTAL_STORES_OVER_50000"}};
		exit(0);
	}

	# First check if we need to disallow the store and ban the ip.
	my $stores_today = get_stores_today_for_ip($dbh, $ip);
	print $fh "Stores today for ip:$ip - stores_today: $stores_today\n";
	if ($stores_today >= 100) {
		# Tell client ip can't store anymore. Don't store.
		print $q->header();
		print qq{{"store_response":"STORES_OVER_100"}};
	} else {
		# Run the store.
		# Store new record into database at fingerprint or modify if fingerprint already exists.
		my $store_response = $dbh->do("INSERT INTO $db_table (fingerprint, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?", undef, $fingerprint, $data, $data);
		# store_response gets 1 on inserting new record, 2 if record was updated. Both indicate 1 piece of data was just stored.
		if ($store_response == 1 or $store_response == 2) {
			# Store succeeded.
			print $fh "store_response: $store_response\n";
			# Run increment command for stores_on_date (more logic to be added later when we set up site-wide shutdown).
			$dbh->do("INSERT INTO $stores_on_date_table (date_stored, stores_on_this_date) VALUES (CURRENT_DATE, 1) ON DUPLICATE KEY UPDATE stores_on_this_date = stores_on_this_date + 1;", undef);
			# Run increment command for stores_today_per_ip.
			$dbh->do("INSERT INTO $stores_today_per_ip_table (ip, stores_today) VALUES (?, 1) ON DUPLICATE KEY UPDATE stores_today = stores_today + 1;", undef, $ip);
			# Report success to client.
			print $q->header();
			print qq{{"store_response":"SUCCESS"}};
		} else {
			# Store failed.
			print $fh "STORE FAILED!";
			# HTTP POST response requires a header.
			print $q->header();
			print qq{{"store_response":"STORE FAILED"}};
		}
	}
} else {
			print $q->header();
			print "DONT TRY TO HACK ME";
}

# Get number of stores today for a given ip.
sub get_total_stores_today {
	my $dbh = shift;
	my $ip = shift;
	# DBI command for returning a single value with SELECT.
	my $total_stores_today = $dbh->selectrow_array("SELECT stores_on_this_date FROM $stores_on_date_table WHERE date_stored = CURRENT_DATE", undef);
	# Empty retun indicates record doesn't exist yet ==> nothing yet stored today.
	if ($total_stores_today eq '') {
		$total_stores_today = 0;
	}
	return $total_stores_today;
}

# Get number of stores today for a given ip.
sub get_stores_today_for_ip {
	my $dbh = shift;
	my $ip = shift;
	# DBI command for returning a single value with SELECT.
	my $stores_today = $dbh->selectrow_array("SELECT stores_today FROM $stores_today_per_ip_table WHERE ip = ?", undef, $ip);
	# Empty retun indicates record doesn't exist yet ==> nothing yet stored today.
	if ($stores_today eq '') {
		$stores_today = 0;
	}
	return $stores_today;
}

sub get_first_line{
	my $location = shift;
	open my $first_line_fh, '<', $location or die "Cannot read server type from file: $!";
	# Read in first line. Should only be 1 line in this file.
	my $first_line= <$first_line_fh>;
	close $first_line_fh;
	chomp($first_line); # Remove newline.
	return $first_line;
}











