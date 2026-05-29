#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
use strict;
use warnings;
#use cPanelUserConfig;

use HTML::Template;
use Time::Piece;
use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;

my $cgi = CGI->new;
# Header link id.
# queries to e.g. obf.mkrsvr.org/faq will get redirected to this script as 'faq' as this id parameter.
my $link_id = CGI::escapeHTML(param('link_id'));

# Set SQL variables
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';
my $stores_on_date_table = 'stores_on_date';
# Get database handler $dbh by successfully connecting to database.
my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
# DBI command for returning a single value with SELECT.
my $total_stores_today = $dbh->selectrow_array("SELECT stores_on_this_date FROM $stores_on_date_table WHERE date_stored = CURRENT_DATE", undef);

# Set filter so this script will use the minimum number of resources in the event of an attack.
if ($total_stores_today < 50000) {

	# Log all site accesses.
	my $t = localtime; # Get current time for log.
	my $time = $t->strftime(); # Make time format human readable.
	my $filename = '/usr/local/apache2/logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "\nSITE ACCESSED\n";
	print $log_fh "$time\n";
	print $log_fh "Link ID parameter: $link_id\n";
	close $log_fh;

	# Last updated on: template variables.
	# Read in htdocs/auto_log 
	# Get last line in file
	# set that to readonly_last_updated
	open my $fh, '<', '/usr/local/apache2/htdocs/auto_update_log.txt'; # or die "Cannot open file: $!";
	# Read entire file into array.
	my @lines = <$fh>;
	# Get the last line in array.
	my $last_updated_status = $lines[-1];
	close $fh;

	# Define human readable hash which will contain anon hashes for our 2-deep hash.
	my %template_data;
	# Read in custom config file. Looks like:
	# variable_name:mainsite_value,readonly_site_value
	open my $cfh, '<', '/usr/local/apache2/htdocs/template_vars.txt' or die "Cannot open file: $!";
	# Iterate over each line in file.
	while (my $line = <$cfh>) {
		next if $line =~ /^#.*$/; # Don't read in commented lines (starting with # like this comment).
		chomp $line; # Remove newline.
		# First split variable name from the 2 pieces of data that will need another split.
		my @variable_then_data = split(/:/, $line);
		# Then split main data values from readonly data values.
		my @main_then_readonly = split(/,/, $variable_then_data[1]);
		# Finally populate 2 deep hash with our 2 split arrays.
		$template_data{ $variable_then_data[0] } = {'main' => $main_then_readonly[0], 'readonly' => $main_then_readonly[1]};
	}
	close $cfh;

	# Select file to build based on site accessed.
	if ($link_id eq "faq") {
		# HTTP Response requires proper header to work.
		print $cgi->header('text/html');
		# Read in static error file unless we have stored less than 50,000 times today.
		open my $fh, '<', 'faq.html';
		print while <$fh>;
		close $fh;   
		exit(0);
	} elsif ($link_id eq "contact") {
		# HTTP Response requires proper header to work.
		print $cgi->header('text/html');
		# Read in static error file unless we have stored less than 50,000 times today.
		open my $fh, '<', 'contact.html';
		print while <$fh>;
		close $fh;   
		exit(0);
	}

	# Read in base template that will be populated with variables below.
	my $template = HTML::Template->new(filename => 'index.tmpl');

	# I think always populate as it will be hidden (display:none) in HTML on main site.
	$template->param(last_updated_status => $last_updated_status);
	# Read in server type.
	my $file_type_location = "/usr/local/apache2/htdocs/this_server_type.txt";
	open my $type_fh, '<', $file_type_location or die "Cannot read server type from file: $!";
	# Read in first line. Should only be 1 line in this file.
	my $server_type = <$type_fh>;
	close $type_fh;
	chomp($server_type); # Remove newline.
	if ($server_type eq "backup") {
		# Set Readonly site variables.
		foreach my $template_variable (keys %template_data) {
			$template->param($template_variable => $template_data{$template_variable}{'readonly'});
		}
	} elsif ($server_type eq "main") {
		# Set Main site variables.
		foreach my $template_variable (keys %template_data) {
			$template->param($template_variable => $template_data{$template_variable}{'main'});
		}
	} else {
		die "Cannot read server type from file!";
	}
	# HTTP Response requires proper header to work.
	print $cgi->header('text/html');
	# Print populated template to HTML Response.
	print $template->output;
} else {
	# Else clause should catch error (like if SQL doesn't work) for security.
	print $cgi->header('text/html');
	# Read in static error file unless we have stored less than 50,000 times today.
	open my $fh, '<', 'over50000_index.html';
	print while <$fh>;
	close $fh;   
	#exit(0);
}

exit(0);




