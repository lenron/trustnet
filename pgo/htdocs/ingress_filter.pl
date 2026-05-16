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

# Main site (green) or read only site (blue) color.
my $main_page_type_color = "#54c597"; # Greenish
my $readonly_page_type_color = "#4491d5"; # Blueish

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
	} else {
		#print "Readonly file DOES NOT exist, this is the main site.\n";
		$template->param(page_type_color => $main_page_type_color);
	}
	# Print header.
	print $cgi->header('text/html');
	# Populate template.
	print $template->output;

	#print "Content-Type: text/html\n\n", $template->output;

	# HTML Response requires proper header to work.
	#print $cgi->header('text/html');
	#open my $fh, '<', 'index.html';
	#print while <$fh>;
	#close $fh;   
} else { # Else clause should catch error (like if SQL doesn't work) for security.
	print $cgi->header('text/html');
	open my $fh, '<', 'over50000_index.html';
	print while <$fh>;
	close $fh;   
	#exit(0);
}

exit(0);



=pod

# Read in base template that will be populated with variables below.
#my $template = HTML::Template->new(filename => 'index.tmpl');

# Determine if readonly or main, have an empty file called 'readonly' if this is a backup site (to be created by launch_backup_server.sh I suppose.
my $home = $ENV{'HOME'};
my $readonly_file_location = "$home/trustnet/pgo/readonly.txt";

if (-e $readonly_file_location) {
    print "Readonly file exists, this is a readonly site.\n";
} else {
    print "Readonly file DOES NOT exist, this is the main site.\n";
}   

my $online_page_type_color = "#54c597";
my $readonly_page_type_color = "#4491d5";
# Populate template inserts with this form: <TMPL_VAR NAME=page_type_color>, where this label is our 'perl template variable': page_type_color
$template->param(page_type_color => $online_page_type_color);
$template->param(page_type_color => $readonly_page_type_color);



my $main = qq{
};

if($id eq 'how'){
	$template->param(htmlblock => $how);
}elsif( $id eq 'faq'){
	$template->param(htmlblock => $faq);
}elsif( $id eq 'delete'){
	$template->param(htmlblock => $delete);
}else{
	$template->param(htmlblock => $main);
}

# send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;


exit 0;

=cut



