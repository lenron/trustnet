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

# Main site (green) or read only site (blue) color template variables.
my $main_page_type_color = "#54c597"; # Greenish
my $readonly_page_type_color = "#4491d5"; # Blueish

# Titletext template variables. 
my $main_titletext = "PGO-SECRETWORD"; #
my $readonly_titletext = "PGO-READONLY WORD"; #

# Show STORE button or hide it (is that enough removed functionality?).
my $main_store_button = "<button class=\"obf_button\" id='' style=\"flex-grow:1\" onclick=\"showPage('store_codeword')\">STORE SECRET DATA</button>"; #
my $readonly_store_button = ""; #


# Last updated on: template variables.
# Read in htdocs/auto_log 
# Get last line in file
# set that to readonly_last_updated
open my $fh, '<', '/usr/local/apache2/htdocs/auto_update_log.txt'; # or die "Cannot open file: $!";
# Read into array from filehandle.
my @lines = <$fh>;
# Get the last line in array.
my $readonly_last_updated = $lines[-1];
close $fh;

# Compile HTML readonly_html_lastupdated_status
my $main_html_lastupdated_status = ""; # Empty. Don't add HTML block showing readonly status on main page.
my $readonly_html_lastupdated_status = qq{
	<!--------------------------Last Synced Status---------------------------!>
	<div id='read_only_div' style="display:flex; justify-content:space-between; flex-direction: row;">
		<div id="main_site_link" style="display:flex; justify-content:space-between; margin:10px;">
			<a href="https://obf.mkrsvr.org"style="color:#54c597">Main Site: obf.mkrsvr.org</a>   
		</div>
		<div id="last_synced_div" style="display:flex; justify-content:space-between; margin:10px;">
			<label id="last_synced_label" style="" >$readonly_last_updated</label>
		</div>
	</div>
};

# Only produce functional file if filter condition met (else clause error is better security).
if ($total_stores_today < 50000) {
	# Read in base template that will be populated with variables below.
	my $template = HTML::Template->new(filename => 'index.tmpl');
	# Determine if readonly or main, have an empty file called 'readonly' if this is a backup site (to be created by launch_backup_server.sh I suppose.
	my $readonly_file_location = "/usr/local/apache2/htdocs/readonly.txt";
	# -e checks for existence of file.
	if (-e $readonly_file_location) {
		#print "Readonly file exists, this is a readonly site.\n";
		$template->param(page_type_color => $readonly_page_type_color);
		$template->param(titletext => $readonly_titletext);
		$template->param(store_button_or_hidden=> $readonly_store_button);
		#$template->param(last_updated => $readonly_last_updated);
		$template->param(readonly_html_lastupdated_status => $readonly_html_lastupdated_status);
	} else {
		#print "Readonly file DOES NOT exist, this is the main site.\n";
		$template->param(page_type_color => $main_page_type_color);
		$template->param(titletext => $main_titletext);
		$template->param(store_button_or_hidden=> $main_store_button);
		#$template->param(last_updated => $main_last_updated);
		$template->param(readonly_html_lastupdated_status => $main_html_lastupdated_status);
	}

	# Print header.
	print $cgi->header('text/html');
	# Print populated template.
	print $template->output;
} else { # Else clause should catch error (like if SQL doesn't work) for security.
	print $cgi->header('text/html');
	open my $fh, '<', 'over50000_index.html';
	print while <$fh>;
	close $fh;   
	#exit(0);
}

exit(0);




