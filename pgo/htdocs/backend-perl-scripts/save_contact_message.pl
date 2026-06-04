#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
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
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';
my $db_contact_messages_table = 'contact_messages';

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
	my $response = $dbh->do("INSERT INTO $db_contact_messages_table (ip, message) VALUES (?, ?)", undef, $ip, $sanitized);

	# Send email to admin.
	send_email('aaronbreault@gmail.com', $sanitized, $ip);

	# HTTP POST response requires a header.
	print $q->header();
	print qq{{"response":"$response"}};
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
	open my $cfh, '<', '/usr/local/apache2/htdocs/smtp_vars.txt' or die "Cannot open file: $!";
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













