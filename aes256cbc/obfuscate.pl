#!/home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
use strict;
use warnings;


use HTML::Template;
use CGI qw(:standard escapeHTML);
use URI::Escape;

my $q = CGI->new;
# Passed in from .htaccess
my $id = CGI::escapeHTML(param('id'));

# open the html template
my $template = HTML::Template->new(filename => 'obfuscate.tmpl');

my $main = qq{

			<div id="generated_html" style="align-self: center; display: flex; flex-direction: column; justify-content: center; color: #54c597">
				<h2>SECURELY STORE DATA AND ACCESS FROM ANY WEB BROWSER</h2>
				<div id="button_div" style="display:flex; justify-content: center">
					<button class="obf_button" id='go_store_thread' onclick="location.href='https://chat.dance/obf/obfuscate.pl?id=store';">STORE SECRET DATA</button>
					<button class="obf_button" id='go_load_thread' onclick="location.href='https://chat.dance/obf/obfuscate.pl?id=load';">ACCESS SECRET DATA</button>
					<button class="obf_button" id='go_import_thread' onclick="location.href='https://chat.dance/obf/obfuscate.pl?id=delete';">IMPORT SECRET DATA</button>
				</div>
			</div>

};

my $store = qq{

};
my $load = qq{

};
my $delete = qq{

};

if( $id eq 'store'){
	$template->param(htmlblock => $store);
}elsif( $id eq 'load'){
	$template->param(htmlblock => $load);
}elsif( $id eq 'delete'){
	$template->param(htmlblock => $delete);
}else{
	$template->param(htmlblock => $main);
}

# send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;


exit 0;







