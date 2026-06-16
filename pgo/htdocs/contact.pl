#!/usr/bin/perl
use strict;
use warnings;

use Time::Piece;
use CGI qw(:standard escapeHTML);

# Create cgi object for html function.
my $cgi = CGI->new;

add_log_message("CONTACT SITE ACCESSED");

# HTTP Response requires proper header to work.
print $cgi->header('text/html');
# Read in static error file unless we have stored less than 50,000 times today.
open my $fh, '<', 'contact.html';
print while <$fh>;
close $fh;   

exit(0);


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











