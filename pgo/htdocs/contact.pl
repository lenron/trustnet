#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(:standard escapeHTML);
require "/usr/local/apache2/htdocs/backend-perl-scripts/pgolib.pl";

# Create cgi object for html function.
my $cgi = CGI->new;

add_log_message_with_time_and_ip("CONTACT SITE ACCESSED");

# HTTP Response requires proper header to work.
print $cgi->header('text/html');
# Read in static error file unless we have stored less than 50,000 times today.
open my $fh, '<', 'contact.html';
print while <$fh>;
close $fh;   

exit(0);




