#!/usr/bin/perl
use strict;
use warnings;
use cPanelUserConfig;

# Shebang line needs changed on server I guess.

use HTML::Template;
#use CGI qw(:standard escapeHTML);
#use URI::Escape;

#my $q = CGI->new;
# Passed in from .htaccess
#my $word1 = CGI::escapeHTML(param('word1'));
#my $word2 = CGI::escapeHTML(param('word2'));

# open the html template
my $template = HTML::Template->new(filename => 'fsobf.tmpl');

my $htmlblock = qq{

	<div>
		<h3>This is from the perl htmlblock variable.</h3>
	</div>
	<div style='display: flex; flex-direction: column; border-style: inset; width: fit-content; padding: 5px;'>
		<div id='1' style="display:flex;">
			<label>First<label>
			<input value="1" id="1" style="width: 400px;"></input>
		</div>
	</div>


};

# always let either the chat or button rooms know who their button room is
$template->param(htmlblock => $htmlblock);

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







