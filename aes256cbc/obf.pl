#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
use strict;
use warnings;
# Not needed when under perlbrew switch I guess?


use HTML::Template;
use CGI qw(:standard escapeHTML);
use URI::Escape;

my $q = CGI->new;
# Passed in from .htaccess
my $test = CGI::escapeHTML(param('test'));

# open the html template
my $template = HTML::Template->new(filename => 'fsobf.tmpl');

my $test1 = qq{
	<div>
		<h3>This is from the perl htmlblock variable.</h3>
	</div>
	<div style='display: flex; flex-direction: column; border-style: inset; width: fit-content; padding: 5px;'>
		<div id='1' style="display:flex;">
			<label>First<label>
			<input value="1" id="1" style="width: 400px;"></input>
			<button type="button" id="home_button" class="home_button" onclick="location.href='https://chat.dance/obf/obf.pl?test=1a';">Home</button>
		</div>
	</div>
};

my $test2 = qq{
	<div>
		<h3>Made It</h3>
	</div>
};

if( $test eq '1a' ){
	$template->param(htmlblock => $test2);
}else{
	$template->param(htmlblock => $test1);
}

# send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;


exit 0;
	# Add data in a loop
	#$template->param(
		#element_ids => [
			#{ id => 'word1' },
			##{ id => 'word2' },
		#]
	#);
#







