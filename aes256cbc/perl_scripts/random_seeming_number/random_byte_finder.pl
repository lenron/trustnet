#!/usr/bin/perl
use warnings;
use strict;

#Program finds random 7-bytes series that sum to a specific set of numbers.

#Details:
#A hash will hold as keys, every number in the given range (e.g. 0-42).
#For each number, a set of 7 unique random bytes will be generated.
#These random bytes, when added/subtracted, will sum to the given number
#and will do so in a repeatable fashion.
#Thus, these 7 random bytes can be used in place of the number, obfuscating it,
#and making it difficult to distinguish from completely random set of bytes
#uncorrelated to the given number. 

#Define the range of numbers we want to find random 7-byte combos for.
my $low_range_num = 0;
my $high_range_num = 2;
my $size_of_random_byte_array = 7;

my $number = int(rand($high_range_num));
find_7bytevalue_for_one_num($number, $size_of_random_byte_array);

generate_7bytevalue_within_num_range($low_range_num, $high_range_num, $size_of_random_byte_array); 
exit(0);


#Generate a hash to hold the numbers, and our discovered 7-byte solutions.
my $num_to_randbyte_hashref = generate_hash_with_key_num_range($low_range_num, $high_range_num);
#Generate byte combos until there's a solution for every number in our range. 
do{
	#Generate 7 random bytes.
	my $rand_arrayref = generate_random_byte_array($size_of_random_byte_array);
	#Sum and subtract the bytes in a random (but repeatable fashion).
	my $rand_array_sum = randomly_add_and_subtract_bytes($rand_arrayref);
	#If the sum of the bytes is equal to a number within our desired range,
	#and has an undefined key->value mappping, store the 7-byte random array as
	#the associated value in the hash, such that these bytes can be used 
	#later to re-create the given number, while simultaneously obscuring it.
	if (exists $num_to_randbyte_hashref->{$rand_array_sum} and not defined $num_to_randbyte_hashref->{$rand_array_sum}){
		$num_to_randbyte_hashref->{$rand_array_sum} = $rand_arrayref; 
	}
} while(randbyte_hash_is_full($num_to_randbyte_hashref) eq "false");

#Once successful, print out the results and stats of our search.
foreach my $num (sort keys %{$num_to_randbyte_hashref}){
	my @rand_byte_summing_array = @{$num_to_randbyte_hashref->{$num}};
	print "-------------------------------------------------\n";
	print "In order for our bytes to sum up to ", $num, "\n";
	print "we should use bytes: ";
	foreach my $byte (@rand_byte_summing_array){
		print "$byte ";
	}
	print "\n";
	my $sum = randomly_add_and_subtract_bytes_print_comments(\@rand_byte_summing_array);
	print "our number: $num, abs(sum): $sum\n";
}
print "-------------------------------------------------\n\n";
print "These are the results for generating random byte sums for numbers from $low_range_num to $high_range_num\n";
ratio_of_successes_to_failures($num_to_randbyte_hashref); 



#Generates a hash with numerical keys from $low to $high.
sub generate_hash_with_key_num_range {
	my $low = shift;
	my $high = shift;
	my %num_to_randbyte;
	for (my $i=$low; $i<=$high; $i++){
		$num_to_randbyte{$i} = undef;
	}
	return \%num_to_randbyte;
}

#Have we mapped every number in our range to a sum of seven random bytes?
sub randbyte_hash_is_full {
	my $hashref = shift;
	my %hash = %{$hashref};
	foreach my $key (sort keys %hash){
		if (!defined($hash{$key})){
			return "false"; 
		}
	}
	return "true";
}

#Generate an array of random bytes (each represented by a number 0-255)
sub generate_random_byte_array {
	my $num_of_bytes = shift;
	my @bytes;
	for (my $i=0; $i<$num_of_bytes; $i++){
#----- To implement rand byte generation in Javascript, use:----
#			const array = new Uint8Array(1);
#			crypto.getRandomValues(array);
#-------------------------------------------
		my $num = int(rand(256));
		push @bytes, $num;
	}
	return \@bytes;
}

#Sums the bytes using the following formula:
#The first byte is added to 0.
#The second byte represents a (+) sign if it's even, a (-) sign if it's odd.
#The third byte is added or subtracted based on the 2nd byte.
#This process continues through to the 7th byte.
#The absolute value of our total is returned.
sub randomly_add_and_subtract_bytes {
	my $rand_bytes_array_ref = shift; #Must always have odd number of bytes.
	my @rand_bytes = @{$rand_bytes_array_ref}; #deference array of bytes.
	my $index = 0; #tracks which of the seven bytes we're on (0-6)
	my $sum = 0; #our mathematical sum/subtract result of all the bytes
	my $add_or_minus = "add"; #tells us if we're adding or subtracting.
	do{
		if ($add_or_minus eq "add"){
			$sum = $sum + $rand_bytes[$index];
		}
		elsif ($add_or_minus eq "minus"){
			$sum = $sum - $rand_bytes[$index];
		}
		$index++; #go to next number
		#Check that number is defined in array.
		if (defined $rand_bytes[$index]){
			#Check if number is even.
			if ($rand_bytes[$index] % 2 == 0){
				$add_or_minus = "add"
			}
			#otherwise number is odd.
			else {
				$add_or_minus = "minus"
			}
		}
		else{
			$sum = abs($sum) if $sum < 0; #change sign if sum is negative.
			return $sum;
		} #Time to exit, there are no bytes left in array. 
		$index++;
	} while (defined $rand_bytes[$index]);
}

#Identical to the subroutine above, but it prints out comments.
sub randomly_add_and_subtract_bytes_print_comments {
	my $rand_bytes_array_ref = shift;
	my @rand_bytes = @{$rand_bytes_array_ref}; #deference array of bytes.
	my $index = 0; #tracks which of the seven bytes we're on (0-6)
	my $sum = 0; #our mathematical sum/subtract result of all the bytes
	my $add_or_minus = "add"; #tells us if we're adding or subtracting.
	do{
		if ($add_or_minus eq "add"){
			print "$sum + $rand_bytes[$index] = ";
			$sum = $sum + $rand_bytes[$index];
			print "$sum\n";
		}
		elsif ($add_or_minus eq "minus"){
			print "$sum - $rand_bytes[$index] = ";
			$sum = $sum - $rand_bytes[$index];
			print "$sum\n";
		}
		$index++; #go to next number
		#Check that number is defined in array.
		if (defined $rand_bytes[$index]){
			#Check if number is even.
			if ($rand_bytes[$index] % 2 == 0){
				print "$rand_bytes[$index] is even, so add\n";
				$add_or_minus = "add"
			}
			#otherwise number is odd.
			else {
				print "$rand_bytes[$index] is odd, so subtract\n";
				$add_or_minus = "minus"
			}
		}
		else{
			$sum = abs($sum) if $sum < 0; #change sign if sum is negative.
			return $sum;
		} #Time to exit, there are no bytes left in array. 
		$index++;
	} while (defined $rand_bytes[$index]);
}

#When our range is 0-5, we've only got 1% sucess rate
#When our range is 0-205, we've got a 1:1 success:fail rate.
#But by the time our range is 0-520, we've got 12 successes for every 1 fail,
#which means that over 90% of the existing 7-random-byte combinations will
#produce a valid number, leaving a potential attacker very little leverage.
sub ratio_of_successes_to_failures {
	my $num_range_hashref = shift;
	my $times_to_try = 10000;
	my $current_try = 0;
	my $success_count = 0;
	my $fail_count = 0;
	do{
		my $rand_arrayref = generate_random_byte_array($size_of_random_byte_array);
		my $rand_array_sum = randomly_add_and_subtract_bytes($rand_arrayref);
		if (exists $num_to_randbyte_hashref->{$rand_array_sum}){
			$success_count++;
		}
		else{
			$fail_count++;
		}
		$current_try++;
	} while($current_try < $times_to_try);
	print "For $times_to_try tries:\n\t$success_count sucesses\n\t$fail_count fails\n\tsuccess:fail ratio was ", $success_count/$fail_count, "\n";
}


#find a single 7-byte random series for a given number.
#This can be used to replace S1.
sub find_7bytevalue_for_one_num {
	my $number = shift;
	my $size_rand_arr = shift;
	my $rand_arrayref;
	my $sum = "nothing yet";

	do{
		#Generate 7 random bytes.
		$rand_arrayref = generate_random_byte_array($size_rand_arr);
		#Sum those bytes.
		$sum = randomly_add_and_subtract_bytes($rand_arrayref);
	} while($sum != $number);


	print "The necessary bytes to generate $number are:\n";
	foreach my $byte (@{$rand_arrayref}){
		print "$byte ";
	}
	print "\n";
}

#For finding random data to replace S2 and fill the no-password database.
sub generate_7bytevalue_within_num_range {
	#Since the openssl data is restricted in length,
	#the range here specifies constrains in line with that length.
	#E.g. we can't have an openssl length of 750, so we shouldn't
	#allow for our 7-byte combos to be equal to 750.
	my $low = shift; #Question: what is the minimum output of openssl?
	my $high = shift;
	my $size_rand_arr = shift;
	my $rand_arrayref;
	my $sum = "nothing yet";

	do{
		#Generate 7 random bytes.
		$rand_arrayref = generate_random_byte_array($size_rand_arr);
		#Sum those bytes.
		$sum = randomly_add_and_subtract_bytes($rand_arrayref);
	} while($high < $sum or $sum < $low);

	print "we generated the num $sum with bytes:\n";
	foreach my $byte (@{$rand_arrayref}){
		print "$byte ";
	}
	print "\n";
}
