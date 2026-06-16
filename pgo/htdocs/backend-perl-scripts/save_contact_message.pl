#!/usr/bin/perl
use strict;
use warnings;
#use cPanelUserConfig;

use Time::Piece;
use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;
use HTML::Entities;

# Create CGI and json objects.
my $q = CGI->new;
my $json = JSON->new;

# Set SQL variables
my $db_table = 'passlock_table';
my $db_name = 'chatriwe_obf';
my $db_contact_messages_table = 'contact_messages';
my $db_username = get_first_line('/run/secrets/mariadb_login');
my $db_pw = get_first_line('/run/secrets/mariadb_pw');
my $contacts_today_per_ip_table = 'contacts_today_per_ip';
my $contacts_on_date_table = 'contacts_on_date';

# Did CGI catch an HTTP Request object ($q->param)?
if ($q->param){
	# Get user IP.
	my $ip = $ENV{REMOTE_ADDR};
	# CGI term POSTDATA is used to get the entire raw body content (in JSON object form).
	my $posted_data_in_json_object_form = $q->param('POSTDATA');
	# Decode json object into hash.
	my $hash_ref = $json->decode($posted_data_in_json_object_form);
	# Extract values from hash.
	my $contact_message = $hash_ref->{message};
	# Sanitize inputs for security.
	my $sanitized = encode_entities($contact_message);

	# Get database handler $dbh by successfully connecting to database.
	my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
	# Check hard limit for total contacts today.
	my $total_contacts_today = get_total_contacts_today($dbh, $ip);
	add_log_message("Total contacts today: $total_contacts_today");
	if ($total_contacts_today >= 1000) {
		# Lock out.
		print $q->header();
		print qq{{"contact_response":"TOTAL_CONTACTS_OVER_1000"}};
		exit(0);
	}

	# First check if we need to disallow the contact and ban the ip.
	my $contacts_today = get_contacts_today_for_ip($dbh, $ip);
	add_log_message("Contacts today for ip: $ip - $contacts_today");
	if ($contacts_today >= 5) { # Nikki limit.
		# Tell client ip they are contacting too much and are banned for 1 day.
		print $q->header();
		print qq{{"contact_response":"CONTACTS_OVER_5"}};
	} else {
		# Run the contact.
		# Save message to contact message table.
		my $save_contact_response = $dbh->do("INSERT INTO $db_contact_messages_table (ip, message) VALUES (?, ?)", undef, $ip, $sanitized);
		# Send email to admin.
		send_email('aaronbreault@gmail.com', $sanitized, $ip);
		if ($save_contact_response == 1) {
			# Run increment command for contacts_on_date (more logic to be added later when we set up site-wide shutdown).
			$dbh->do("INSERT INTO $contacts_on_date_table (date_contacted, contacts_on_this_date) VALUES (CURRENT_DATE, 1) ON DUPLICATE KEY UPDATE contacts_on_this_date = contacts_on_this_date + 1;", undef);
			# Run increment command for contacts_today_per_ip.
			$dbh->do("INSERT INTO $contacts_today_per_ip_table (ip, contacts_today) VALUES (?, 1) ON DUPLICATE KEY UPDATE contacts_today = contacts_today + 1;", undef, $ip);
			# Report success to client.
			print $q->header();
			print qq{{"contact_response":"SUCCESS"}};
		} else {
			# HTTP POST response requires a header.
			print $q->header();
			print qq{{"contact_response":"CONTACT_FAILED"}};
		}
	}
}


# Send message to inputted email using swaks, smtp.
sub send_email {
	my $admin_email = shift; #'aaronbreault@gmail.com';
	my $sanitized_message = shift;
	my $ip = shift;
	# Read in swaks/proton variables from conf file.
	my %email_vars = get_email_vars();
	# Run swaks command from command line. This will run from inside the container.
	my $std_output_a = `swaks --from $email_vars{username} --to $admin_email --server $email_vars{server} --port $email_vars{port} --auth plain --tls --auth-user '$email_vars{username}' --auth-password '$email_vars{password}' --header 'Subject: PGO Contact Message Received' --body "$sanitized_message"`;
	add_log_message("SAVING CONTACT MESSAGE\nIP: $ip\nEmail attempt std_out: $std_output_a");
}

# Read in SMTP settings from config file.
sub get_email_vars {
	# Hash for readability.
	my %email_data;
	# Read in custom config file. Looks like:  variable_name:mainsite_value,readonly_site_value
	#open my $cfh, '<', '/usr/local/apache2/htdocs/smtp_vars.txt' or die "Cannot open file: $!";
	open my $cfh, '<', '/run/secrets/email_creds' or die "Cannot open file: $!";
	# Iterate over each line in file.
	while (my $line = <$cfh>) {
		next if $line =~ /^#.*$/; # Don't read in commented lines (starting with # like this comment).
		chomp $line; # Remove newline.
		# Variable label will go in 0th index, variable value will populate to 1st index.
		my @variable_then_data = split(/:/, $line);
		$email_data{ $variable_then_data[0] } = $variable_then_data[1];
	}
	close $cfh;
	# Return populated data.
	return %email_data;
}

# Add log message - string passed into this function.
sub add_log_message {
	my $message = shift;
	# Log all site accesses.
	my $t = localtime; # Get current time for log.
	my $time = $t->strftime(); # Make time format human readable.
	my $filename = '/usr/local/apache2/logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "\n$message\n";
	print $log_fh "$time\n";
	close $log_fh;
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

# Get number of contacts today for a given ip.
sub get_total_contacts_today {
	my $dbh = shift;
	my $ip = shift;
	# DBI command for returning a single value with SELECT.
	my $total_contacts_today = $dbh->selectrow_array("SELECT contacts_on_this_date FROM $contacts_on_date_table WHERE date_contacted = CURRENT_DATE", undef);
	# Empty retun indicates record doesn't exist yet ==> nothing yet contacted today.
	if ($total_contacts_today eq '') {
		$total_contacts_today = 0;
	}
	return $total_contacts_today;
}

# Get number of contacts today for a given ip.
sub get_contacts_today_for_ip {
	my $dbh = shift;
	my $ip = shift;
	# DBI command for returning a single value with SELECT.
	my $contacts_today = $dbh->selectrow_array("SELECT contacts_today FROM $contacts_today_per_ip_table WHERE ip = ?", undef, $ip);
	# Empty retun indicates record doesn't exist yet ==> nothing yet contacted today.
	if ($contacts_today eq '') {
		$contacts_today = 0;
	}
	return $contacts_today;
}









