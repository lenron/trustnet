# Install apache2 
FROM httpd:2.4
# Copy in conf to enable perl cgi, .htaccess, etc.
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
# Get updated list of apt-get programs.
RUN apt-get update
# Add swaks for email function.
RUN apt-get install -y swaks 
# Install perl modules. Prefer apt-get for scripts.
RUN apt-get install -y make gcc cpanminus
RUN apt-get install -y libmariadb-dev
RUN cpanm DBI
RUN cpanm DBD::MariaDB
RUN cpanm CGI
RUN cpanm Time::Piece
RUN cpanm URI::Escape
RUN cpanm JSON
RUN cpanm HTML::Template
# Enable perl module. This might be enablable in conf file.
CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
