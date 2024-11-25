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
					<button class="obf_button" id='go_store_thread' onclick="location.href='https://chat.dance/obf/store';">STORE SECRET DATA</button>
					<button class="obf_button" id='go_load_thread' onclick="location.href='https://chat.dance/obf/load';">ACCESS SECRET DATA</button>
					<button class="obf_button" id='go_delete_thread' onclick="location.href='https://chat.dance/obf/delete';">DELETE SECRET DATA</button>
				</div>
			</div>

};

my $store = qq{
<!--   store  --!>
			<div class="gen store one" id="store1" style="">
				<label>STORE DATA</label>
				<h2>ENTER CODE WORD TO HELP YOU REMEMBER YOUR SECRET DATA</h2>
				<input autofocus onkeydown="catchEnter(event)" value="" id="store_codeword" style="">
				<button class="" id='sf1' style="width: 250px;" onclick="storeOne()">NEXT</button>
			</div>

			<div class="gen store two" id="store2" style="display:none">
				<label>STORE DATA</label>
				<textarea value="" id="store_data" rows="8" cols="50" placeholder="ENTER YOUR SECRET DATA"></textarea>
				<button class="" id='sf2' style="width: 250px; align-self:center;" onclick="storeTwo()">ENCRYPT DATA</button>
			</div>

			<div class="gen store three" id="store3" style="display:none">
				<label>&#10004; SECRET DATA SAVED</label>
				<h2>ENTER SECRET WORD 1</h2>
				<input onkeydown="catchEnter(event)" value="" id="store_pass_1" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="deepStore()">DEEP STORE DATA</button>	--!>
					<button class="" id='sf3' style="flex-grow:1;" onclick="storeThree()">ENHANCE SECURITY</button>
				</div>
			</div>

			<div class="gen store four" id="store4" style="display:none">
				<label>&#10004; SECRET DATA SAVED</label>
				<label>&#10004; SECRET WORD 1 SAVED</label>
				<h2>ENTER SECRET WORD 2</h2>
				<input onkeydown="catchEnter(event)" value="" id="store_pass_2" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="deepStore()">DEEP STORE DATA</button>	--!>
					<button class="" id='sf4' style="flex-grow:1;" onclick="storeFour()">ENHANCE SECURITY</button>
				</div>
			</div>

			<div class="gen store five" id="store5" style="display:none">
				<label>&#10004; SECRET DATA SAVED</label>
				<label>&#10004; SECRET WORD 1 SAVED</label>
				<label>&#10004; SECRET WORD 2 SAVED</label>
				<h2>ENTER SECRET WORD 3</h2>
				<input onkeydown="catchEnter(event)" value="" id="store_pass_3" style="">
				<button class="" id='deepstorebutton' style="width:50%;align-self:center;" onclick="storeFive()">DEEP STORE DATA</button>
			</div>

			<div class="gen store six" id="store6" style="display:none">
				<h2>&#10004; SECRET DATA SUCCESSFULLY STORED AND ENCRYPTED</h2>
				<div class="button_pair" id="button_pair" style="display:flex;">
					<button class="" id='learnmore' style="width:400px;" onclick="location.href='https://chat.dance/obf/how';">LEARN MORE</button>
					<button class="" id='accessdata' style="width:400px;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
				</div>
			</div>

			<div class="gen store seven" id="store7" style="display:none">
				<h2>&#10060; FAILED </h2>
				<div class="button_pair" id="button_pair" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='accessdata' style="flex-grow:1" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
				</div>
			</div>
<!--  store  --!>
};

my $load = qq{
<!--   load  --!>
			<div class="gen load one" id="load1" style="">
				<label>ACCESS DATA</label>
				<h2>ENTER CODE WORD</h2>
				<input autofocus onkeydown="catchEnter(event)" value="" id="load_codeword" style="">
				<button class="" id='lf1' style="width: 250px;" onclick="loadOne()">NEXT</button>
			</div>

			<div class="gen load two" id="load2" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<h2>ENTER SECRET WORD 1</h2>
				<input onkeydown="catchEnter(event)" value="" id="load_pass_1" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf2' style="flex-grow:1;" onclick="loadTwo()">NEXT</button>
				</div>
			</div>

			<div class="gen load three" id="load3" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<h2>ENTER SECRET WORD 2</h2>
				<input onkeydown="catchEnter(event)" value="" id="load_pass_2" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf3' style="flex-grow:1;" onclick="loadThree()">NEXT</button>
				</div>
			</div>

			<div class="gen load four" id="load4" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<label>&#10004; SECRET WORD 2 ENTERED</label> 
				<h2>ENTER SECRET WORD 3</h2>
				<input onkeydown="catchEnter(event)" value="" id="load_pass_3" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--				<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf4' style="flex-grow:1;" onclick="loadFour()">ACCESS DATA</button>
				</div>
			</div>

			<div class="gen load five" id="load5" style="display:none">
				<label>&#10004; SUCCESS</label>
				<label>result:</label>
				<textarea value="" id="output_display" rows="8" cols="50"></textarea>
				<div class="button_pair" id="button_pair" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='go_load' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
				</div>
			</div>

<!--   load  --!>
};

my $how = qq{
<!--   how	--!>
			<div class="gen how" id="generated_html" style="">
				<h3>How it Works Section</h3>
			</div>
<!--   how	--!>
};

my $faq = qq{ 
<!--   faq	--!>
			<div class="gen faq" id="generated_html" style="">
				<h3>FAQ Section</h3>
			</div>
<!--   faq	 --!>
};

my $delete = qq{
<!--   delete	 --!>
			<div class="gen delete one" id="delete1" style="">
				<label>DELETE DATA</label>
				<h2>ENTER CODE WORD</h2>
				<input autofocus onkeydown="catchEnter(event)" value="" id="delete_codeword" style="">
				<button class="" id='lf1' style="width: 250px;" onclick="deleteOne()">NEXT</button>
			</div>

			<div class="gen delete two" id="delete2" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<h2>ENTER SECRET WORD 1</h2>
				<input onkeydown="catchEnter(event)" value="" id="delete_pass_1" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf2' style="flex-grow:1;" onclick="deleteTwo()">NEXT</button>
				</div>
			</div>

			<div class="gen delete three" id="delete3" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<h2>ENTER SECRET WORD 2</h2>
				<input onkeydown="catchEnter(event)" value="" id="delete_pass_2" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--			<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf3' style="flex-grow:1;" onclick="deleteThree()">NEXT</button>
				</div>
			</div>

			<div class="gen delete four" id="delete4" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<label>&#10004; SECRET WORD 2 ENTERED</label> 
				<h2>ENTER SECRET WORD 3</h2>
				<input onkeydown="catchEnter(event)" value="" id="delete_pass_3" style="">
				<div class="button_pair" id="button_pair" style="display:flex;">
	<!--				<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="">BACK</button>     --!>
					<button class="" id='lf4' style="flex-grow:1;" onclick="deleteFour()">ACCESS DATA</button>
				</div>
			</div>

			<div class="gen delete five" id="delete5" style="display:none">
				<label>&#10004; SUCCESS</label>
				<div class="button_pair" id="button_pair" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='go_load' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
					<button class="obf_button" id='go_delete_thread' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/delete';">DELETE DATA</button>
				</div>
			</div>
<!--   delete	 --!>
};


if( $id eq 'store'){
	$template->param(htmlblock => $store);
}elsif( $id eq 'load'){
	$template->param(htmlblock => $load);
}elsif( $id eq 'how'){
	$template->param(htmlblock => $how);
}elsif( $id eq 'faq'){
	$template->param(htmlblock => $faq);
}elsif( $id eq 'delete'){
	$template->param(htmlblock => $delete);
}else{
	$template->param(htmlblock => $main);
}

# send the obligatory Content-Type and print the template output
print "Content-Type: text/html\n\n", $template->output;


exit 0;







