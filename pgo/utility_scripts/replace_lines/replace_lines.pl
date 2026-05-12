#!/usr/bin/perl
use warnings;
use strict;

my $file = $ARGV[0];
my $oldline_newline_file = $ARGV[1];
my %oldline_newline;

open (my $oldline_newline_fh, "<", $oldline_newline_file);
while(my $line = <$oldline_newline_fh>){
	chomp $line;
	my $old_line = $line;
	$line = <$oldline_newline_fh>;
	chomp $line;
	my $new_line = $line;
	<$oldline_newline_fh>;
	$oldline_newline{$old_line} = $new_line;
}

#Check for matches, and reverse our line match hash if necessary.
if ("no" eq matches_found($file, \%oldline_newline)){
	%oldline_newline = reverse %oldline_newline;
	die "No matches found!\n" unless "yes" eq matches_found($file, \%oldline_newline);
}

replace_oldline_with_newline($file, \%oldline_newline);

sub replace_oldline_with_newline {
	my $file = shift;
	my $old_new_hashref = shift;
	my %hash = %{$old_new_hashref};
	
	#Create our new file to replace old file with after substituting matches.
	open (my $new_fh, ">", "new_$file");
	open (my $fh, "<", $file);
	while(my $line = <$fh>){
		my $match_found = "no";
		foreach my $oldline (keys %hash){
			if ($line =~ /^\Q$oldline\E$/){
				$match_found = "yes";
				print $new_fh $oldline_newline{$oldline}, "\n";
			}
		}
		if ($match_found eq "no"){
			print $new_fh $line;
		}
	}
	close $new_fh;
	rename "new_$file", $file;
}

sub matches_found {
	my $file = shift;
	my $old_new_hashref = shift;
	my %hash = %{$old_new_hashref};

	my $match_found = "no";
	open (my $fh, "<", $file);
	while(my $line = <$fh>){
		foreach my $oldline (keys %hash){
			if ($line =~ /^\Q$oldline\E$/){
				$match_found = "yes";
			}
		}
	}
	return $match_found;
}

