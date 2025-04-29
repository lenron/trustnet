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

			<div class="gen home" style="align-self: center; display: flex; flex-direction: column; justify-content: center; color: #54c597">
				<h2>SECURELY STORE DATA AND ACCESS FROM ANY WEB BROWSER</h2>
				<div class="home_buttons" id="" style="display:flex; justify-content: center;">
					<button class="obf_button" id='go_store_thread' style="flex-grow:1" onclick="location.href='https://chat.dance/obf/store';">STORE SECRET DATA</button>
					<button class="obf_button" id='go_load_thread' style="flex-grow:1" onclick="location.href='https://chat.dance/obf/load';">ACCESS SECRET DATA</button>
				</div>
			</div>

};
# 						onclick="openCity('Tokyo')"
my $store = qq{
<!--   store  --!>

<!--
Multiline Comment Reminder
-->

			<div class="gen store one" id="store1" style="display:flex">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>STORE DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<h2>ENTER CODE WORD TO HELP YOU REMEMBER YOUR SECRET DATA</h2>
				<input type="password" autofocus id="store_codeword" style="">
				<div class="button_pair" id="" style="display:flex">
					<button class="" id='' style="flex-grow:1" onclick="location.href='https://chat.dance/obf';">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="checkPassLength('store1','store_choose')">NEXT</button>
				</div>
			</div>

			<div class="gen store choose" id="store_choose" style="display:none">
				<label>STORE DATA</label>
				<h2 style="align-self:center;">CHOOSE WHERE TO ENCRYPT YOUR DATA</h2>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('store1')">BACK</button>
					<div class="informative_button_set" id="" style="flex-grow:3; display:flex; display:flex; flex-direction:column;">
						<button class="" id='' style="display:flex; flex-direction:column; justify-content:center; align-items:center;" onclick="storeDefault()">
							<span style="">BROWSER</span>
							<span style="margin-top:4px; color:gray; font-size:15px;">Text Input</span>
						</button>
					</div>
					<div class="informative_button_set" id="" style="flex-grow:3; display:flex; display:flex; flex-direction:column;">
						<button class="" id='' style="display:flex; flex-direction:column; justify-content:center;" onclick="storeUpload()">
							<span class="coolpink" style="">COMMAND LINE</span>
							<span style="margin-top:4px; color:gray; font-size:15px;">File Input</span>
						</button>
						<label class="coolpink" style="align-self:center;">More Secure</label>
					</div>
				</div>
			</div>

			<div class="gen store upload" id="store_upload" style="display:none">
				<label>STORE DATA</label>
				<h2>UPLOAD FILE</h3>
				<h2 id="store_upload_warning" style="color:red; display:none">FILE TOO LARGE. 700 byte limit</h2>
				<input onchange="catchUpload(event)" id="store_upload_input" style="border:none;" type="file">
				<br>
				<label>OpenSSL Linux <span class="coolpink" style="">Command Line</span> Usage:</label>
				<div style='display: flex; flex-direction: column; border-style: inset; width: fit-content; padding: 5px;'>
					<label>Encrypt:</label>
					<label>openssl enc -aes-256-cbc <span class="coolpink" style="">-e</span> -p -pbkdf2 -in <span class="coolpink">yourfile.txt</span> -out <span class="coolpink">yourfile.enc</span></label>
					<br>
					<label>Decrypt:</label>
					<label>openssl enc -aes-256-cbc <span class="coolpink" style="">-d</span> -p -pbkdf2 -in <span class="coolpink">yourfile.enc</span> -out <span class="coolpink">yourfile.dec</span></label>
				</div>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="width:250px;" onclick="showPage('store_choose')">BACK</button>
					<button class="" id='store_upload_continue' style="flex-grow:1;display:none;" onclick="showPage('store4')">CONTINUE</button>
				</div>
			</div>

			<div class="gen store two" id="store2" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>STORE DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<textarea value="" id="store_data" rows="8" cols="45" oninput="checkTextInputLength()" placeholder="ENTER YOUR SECRET DATA"></textarea>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('store_choose')">BACK</button>
					<button class="" id='store_text_input_continue' style="flex-grow:1" onclick="showPage('store3')">ENCRYPT DATA</button>
					<div id='store_text_input_warning' style="flex-grow:1;display:none;">
						<h2 id='' style="color:red;">TOO MUCH DATA</h2>
					</div>
				</div>
			</div>

			<div class="gen store three" id="store3" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>STORE DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; SECRET DATA SAVED</label>
				<h2>ENTER SECRET WORD 1</h2>
				<input type="password" value="" id="store_pass_1" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1;" onclick="showPage('store2')">BACK</button>
					<button class="" id='' style="flex-grow:1;" onclick="checkPassLength('store3','store4')">ENHANCE SECURITY</button>
				</div>
			</div>

			<div class="gen store four" id="store4" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>STORE DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; SECRET DATA SAVED</label>
				<label>&#10004; SECRET WORD 1 SAVED</label>
				<h2>ENTER SECRET WORD 2</h2>
				<input type="password" value="" id="store_pass_2" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1;" onclick="storeBack()">BACK</button>
					<button class="" id='' style="flex-grow:1;" onclick="checkPassLength('store4','store5')">ENHANCE SECURITY</button>
				</div>
			</div>

			<div class="gen store five" id="store5" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>STORE DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; SECRET DATA SAVED</label>
				<label>&#10004; SECRET WORD 1 SAVED</label>
				<label>&#10004; SECRET WORD 2 SAVED</label>
				<h2>ENTER SECRET WORD 3</h2>
				<input type="password" value="" id="store_pass_3" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1;" onclick="showPage('store4')">BACK</button>
					<button class="" id='deepstorebutton' style="flex-grow:1;" onclick="checkPassLength('store5','executeStore')">DEEP STORE DATA</button>
				</div>
			</div>

			<div class="gen store six" id="store6" style="display:none">
				<h2>&#10004; SECRET DATA SUCCESSFULLY STORED AND ENCRYPTED</h2>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='learnmore' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/how';">LEARN MORE</button>
					<button class="" id='accessdata' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
				</div>
			</div>

			<div class="gen store seven" id="store7" style="display:none">
				<h2>&#10060; FAILED </h2>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='accessdata' style="flex-grow:1" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
				</div>
			</div>

<!-- Catch Upload Data --!>
<input type="password" value="" id="upload_data" style="display:none;">
<!--  store  --!>
};

my $load = qq{
<!--   load  --!>
			<div class="gen load one" id="load1" style="">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>ACCESS DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<h2>ENTER CODE WORD</h2>
				<input type="password" autofocus  value="" id="load_codeword" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf';">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="checkPassLength('load1','load_choose')">NEXT</button>
				</div>
			</div>

			<div class="gen load choose" id="load_choose" style="display:none">
				<label>ACCESS DATA</label>
				<h2 style="align-self:center;">CHOOSE WHERE TO DECRYPT YOUR DATA</h2>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('load1')">BACK</button>
					<div class="informative_button_set" id="" style="flex-grow:3; display:flex; display:flex; flex-direction:column;">
						<button class="" id='' style="display:flex; flex-direction:column; justify-content:center; align-items:center;" onclick="loadDefault()">
							<span style="">BROWSER</span>
							<span style="margin-top:4px; color:gray; font-size:15px;">Text Output</span>
						</button>
					</div>
					<div class="informative_button_set" id="" style="flex-grow:3; display:flex; display:flex; flex-direction:column;">
						<button class="" id='' style="display:flex; flex-direction:column; justify-content:center;" onclick="loadDownload()">
							<span style="color:#ff00ff;text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;">COMMAND LINE</span>
							<span style="margin-top:4px; color:gray; font-size:15px;">File Output</span>
						</button>
						<label style="align-self:center; color:#ff00ff;text-shadow: -1px -1px 0 #000, 1px -1px 0 #000, -1px 1px 0 #000, 1px 1px 0 #000;">More Secure</label>
					</div>
				</div>
			</div>

			<div class="gen load two" id="load2" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>ACCESS DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; CODE WORD ENTERED</label> 
				<h2>ENTER SECRET WORD 1</h2>
				<input type="password"  value="" id="load_pass_1" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('load_choose')">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="checkPassLength('load2','load3')">NEXT</button>
				</div>
			</div>

			<div class="gen load three" id="load3" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>ACCESS DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<h2>ENTER SECRET WORD 2</h2>
				<input type="password"  value="" id="load_pass_2" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="loadBack()">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="checkPassLength('load3','load4')">NEXT</button>
				</div>
			</div>

			<div class="gen load four" id="load4" style="display:none">
				<div style="display: flex; flex-direction: row; justify-content: space-between;">
					<label>ACCESS DATA</label>
					<label class="pass_length_warn" style="color:red; display: none;">Password too short!</label>
				</div>
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<label>&#10004; SECRET WORD 2 ENTERED</label> 
				<h2>ENTER SECRET WORD 3</h2>
				<input type="password"  value="" id="load_pass_3" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('load3')">BACK</button>
					<button class="" id='' style="flex-grow:1;" onclick="checkPassLength('load4','executeLoad')">ACCESS DATA</button>
				</div>
			</div>

			<div class="gen load text" id="load_text" style="display:none">
				<label>&#10004; SUCCESS</label>
				<label>result:</label>
				<div class="overlay_container" style="position:relative">
					<textarea value="" id="output_display" rows="8" cols="50"></textarea>
					<div id="overlay_text" class="deletecheck" style="">
						<h2>Are you sure you want to delete this data?</h2> 
						<div class="button_pair" id="" style="display:flex;">
							<button class="" id='' style="flex-grow:1" onclick="deleteCheckHide('overlay_text')">KEEP DATA</button>
							<button class="" id='' style="flex-grow:1;" onclick="deleteExecute()">DELETE DATA</button>
						</div>
					</div>
				</div>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='go_load' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
					<button class="" id='' style="flex-grow:1" onclick="deleteCheckShow('overlay_text')">DELETE DATA</button>
				</div>
			</div>

			<div class="gen load download" id="load_download" style="display:none">
				<label>&#10004; SUCCESS</label>
				<label>File should automatically download.</label>
				<br>
				<div class="overlay_container" style="position:relative">
					<label>OpenSSL Linux <span class="coolpink" style="">Command Line</span> Usage:</label>
					<div style='display: flex; flex-direction: column; border-style: inset; width: fit-content; padding: 5px;'>
						<label>Encrypt:</label>
						<label>openssl enc -aes-256-cbc <span class="coolpink" style="">-e</span> -p -pbkdf2 -in <span class="coolpink">yourfile.txt</span> -out <span class="coolpink">yourfile.enc</span></label>
						<br>
						<label>Decrypt:</label>
						<label>openssl enc -aes-256-cbc <span class="coolpink" style="">-d</span> -p -pbkdf2 -in <span class="coolpink">yourfile.enc</span> -out <span class="coolpink">yourfile.dec</span></label>
					</div>
					<div id="overlay_download" class="deletecheck" style="">
						<h2>Are you sure you want to delete this data?</h2> 
						<div class="button_pair" id="" style="display:flex;">
							<button class="" id='' style="flex-grow:1" onclick="deleteCheckHide('overlay_download')">KEEP DATA</button>
							<button class="" id='' style="flex-grow:1;" onclick="deleteExecute()">DELETE DATA</button>
						</div>
					</div>
				</div>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='go_load' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
					<button class="" id='' style="flex-grow:1" onclick="deleteCheckShow('overlay_download')">DELETE DATA</button>
				</div>
			</div>

			<div class="gen delete five" id="delete5" style="display:none">
				<label>&#10004; SUCCESS</label>
				<div class="button_pair" id="" style="display:flex;">
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
				<input type="password" autofocus  value="" id="delete_codeword" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf';">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete2')">NEXT</button>
				</div>
			</div>

			<div class="gen delete two" id="delete2" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<h2>ENTER SECRET WORD 1</h2>
				<input type="password"  value="" id="delete_pass_1" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete1')">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete3')">NEXT</button>
				</div>
			</div>

			<div class="gen delete three" id="delete3" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<h2>ENTER SECRET WORD 2</h2>
				<input type="password"  value="" id="delete_pass_2" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete2')">BACK</button>
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete4')">NEXT</button>
				</div>
			</div>

			<div class="gen delete four" id="delete4" style="display:none">
				<label>&#10004; CODE WORD ENTERED</label> 
				<label>&#10004; SECRET WORD 1 ENTERED</label> 
				<label>&#10004; SECRET WORD 2 ENTERED</label> 
				<h2>ENTER SECRET WORD 3</h2>
				<input type="password"  value="" id="delete_pass_3" style="">
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='' style="flex-grow:1" onclick="showPage('delete3')">BACK</button>
					<button class="" id='' style="flex-grow:1;" onclick="deleteExecute()">DELETE DATA</button>
				</div>
			</div>

			<div class="gen delete five" id="delete5" style="display:none">
				<label>&#10004; SUCCESS</label>
				<div class="button_pair" id="" style="display:flex;">
					<button class="" id='go_store' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/store';">STORE DATA</button>
					<button class="" id='go_load' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/load';">ACCESS DATA</button>
					<!--<button class="" id='' style="flex-grow:1;" onclick="location.href='https://chat.dance/obf/delete';">DELETE DATA</button>--!>
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







