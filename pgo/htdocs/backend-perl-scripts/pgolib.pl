#!/usr/bin/perl
use strict;
use warnings;

use Time::Piece;

# Get first line of a file.
sub get_first_line{
	my $location = shift;
	open my $first_line_fh, '<', $location or die "Cannot read server type from file: $!";
	# Read in first line. Should only be 1 line in this file.
	my $first_line= <$first_line_fh>;
	close $first_line_fh;
	chomp($first_line); # Remove newline.
	return $first_line;
}

# Add log message - string passed into this function.
sub add_log_message {
	my $message = shift;
	# Log all site accesses.
	my $filename = '/usr/local/apache2/pgo-logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "$message\n";
	close $log_fh;
}

# Add log message - string passed into this function.
sub add_onlinecheck_log_message {
	my $message = shift;
	# Get user IP.
	my $ip = $ENV{REMOTE_ADDR};
	# Log all site accesses.
	my $t = localtime; # Get current time for log.
	my $time = $t->strftime(); # Make time format human readable.
	my $filename = '/usr/local/apache2/pgo-logs/online_check_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "$message\n";
	print $log_fh "$time\n$ip\n";
	close $log_fh
}

# Add log message - string passed into this function.
sub add_log_message_with_time_and_ip {
	my $message = shift;
	# Get user IP.
	my $ip = $ENV{REMOTE_ADDR};
	# Log all site accesses.
	my $t = localtime; # Get current time for log.
	my $time = $t->strftime(); # Make time format human readable.
	my $filename = '/usr/local/apache2/pgo-logs/log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "$message\n";
	print $log_fh "$ip  @  $time\n";
	close $log_fh
}

# Add log message - string passed into this function.
sub add_passlock_log {
	my $message = shift;
	# Log all site accesses.
	my $filename = '/usr/local/apache2/pgo-logs/passlock_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "$message\n";
	close $log_fh;
}

# Add log message - string passed into this function.
sub add_passlock_log_with_time_and_ip {
	my $message = shift;
	# Get user IP.
	my $ip = $ENV{REMOTE_ADDR};
	# Log all site accesses.
	my $t = localtime; # Get current time for log.
	my $time = $t->strftime(); # Make time format human readable.
	my $filename = '/usr/local/apache2/pgo-logs/passlock_log.txt';
	# Append to existing file if it exists, create new otherwise.
	open(my $log_fh, '>>', $filename); # or die;
	print $log_fh "$message\n";
	print $log_fh "$time\n$ip\n";
	close $log_fh
}

# Perl libraries are required to end with 1 (true) to show this file was loaded successfully.
1; # VERY IMPORTANT!





