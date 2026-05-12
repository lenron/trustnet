# Install apache2 
FROM httpd:2.4
# Copy in conf to enable perl cgi, .htaccess, etc.
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
# Create link to perl inside container 
RUN mkdir -p /home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin
RUN ln -s /usr/bin/perl /home/chatriwe/perl5/perlbrew/perls/perl-5.10.1/bin/perl5.10.1
# Install perl modules. Prefer apt-get for scripts.
RUN apt-get update
RUN apt-get install -y make gcc cpanminus
RUN apt-get install -y libmariadb-dev
RUN cpanm DBI
RUN cpanm DBD::MariaDB
RUN cpanm CGI
RUN cpanm Time::Piece
RUN cpanm URI::Escape
RUN cpanm JSON
# Enable perl module. This might be enablable in conf file.
CMD httpd-foreground -c "LoadModule cgid_module modules/mod_cgid.so"
