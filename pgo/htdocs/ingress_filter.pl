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

# Set SQL variables
my $db_username = 'chatriwe_admin';
my $db_pw = 'Vuu_fQY1#qH,';
my $db_name = 'chatriwe_obf';
my $stores_on_date_table = 'stores_on_date';

my $cgi = CGI->new;

# Get database handler $dbh by successfully connecting to database.
my $dbh = DBI->connect("dbi:MariaDB:$db_name", $db_username, $db_pw);
# DBI command for returning a single value with SELECT.
my $total_stores_today = $dbh->selectrow_array("SELECT stores_on_this_date FROM $stores_on_date_table WHERE date_stored = CURRENT_DATE", undef);

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
open my $cfh, '<', '/usr/local/apache2/htdocs/index_template_vars.txt'; # or die "Cannot open file: $!";
# Iterate over each line in file.
while (my $line = <$cfh>) {
	next if $line =~ /^#.*$/; # Don't read in commented lines (starting with # like this comment).
	chomp $line; # Remove newline.
	# First split variable name from the 2 pieces of data that will need another split.
	my @variable_then_data = split(/:/, $line);
	# Then split main data values from readonly data values.
	my @main_then_readonly = split(/,/, $variable_then_data[1]);
	# Finally populate 2 deep hash with our 2 split arrays.
	$template_data{ $variable_then_data[0] } = { 'main' => $main_then_readonly[0], 'readonly' => $main_then_readonly[1] };
}
close $cfh;

# Only produce functional file if filter condition met (else clause error is better security).
if ($total_stores_today < 50000) {
	# Read in base template that will be populated with variables below.
	my $template = HTML::Template->new(filename => 'index.tmpl');
	# I think always populate as it will be hidden (display:none) in HTML on main site.
	$template->param(last_updated_status => $last_updated_status);
	# Determine if readonly or main, have an empty file called 'readonly' if this is a backup site (to be created by launch_backup_server.sh I suppose.
	my $readonly_file_location = "/usr/local/apache2/htdocs/readonly.txt";
	# -e checks for existence of file.
	if (-e $readonly_file_location) {
		#print "Readonly file exists, this is a readonly site.\n";
		# Set Readonly site variables.
		foreach my $template_variable (keys %template_data) {
			$template->param($template_variable => $template_data{$template_variable}{'readonly'});
		}
	} else {
		#print "Readonly file DOES NOT exist, this is the main site.\n";
		# Set Main site variables.
		foreach my $template_variable (keys %template_data) {
			$template->param($template_variable => $template_data{$template_variable}{'main'});
		}
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




