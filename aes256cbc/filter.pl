#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
use strict;
use warnings;
#use cPanelUserConfig;

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

# If log exists, we know q->param caught data.
#my $filename = './logs/log.txt';
# Append to existing file if it exists, create new otherwise.
#open(my $fh, '>>', $filename); # or die;
#print $fh "\nHOME PERL HIT\n";
#print $fh "total stores today: $total_stores_today\n\n";

if ($total_stores_today >= 50000) {
	print $cgi->header('text/html');
	open my $fh, '<', 'over50000_index.html';
	print while <$fh>;
	close $fh;   
	#exit(0);
} else {
	print $cgi->header('text/html');
	open my $fh, '<', 'index.html';
	print while <$fh>;
	close $fh;   
}

exit(0);








