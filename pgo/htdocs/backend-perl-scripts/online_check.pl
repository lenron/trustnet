#!/usr/bin/perl
use strict;
use warnings;

# online_check.pl
# Provides a simple relay to the client, indicating that client is online.

use CGI qw(:standard escapeHTML);
use DBI;
use URI::Escape;
use JSON;
# Use custom library.
require "/usr/local/apache2/htdocs/backend-perl-scripts/pgolib.pl";

# Create CGI and json objects.
my $q = CGI->new;

add_onlinecheck_log_message("ONLINE CHECK");

my $response = "success";
# HTTP POST response requires a header.
print $q->header();
print qq{{"response":"$response"}};


