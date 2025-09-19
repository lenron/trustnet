FROM httpd:2.4
COPY ./httpd.conf /usr/local/apache2/conf/httpd.conf
# Copy server files into the apache container.
COPY ./index.html /usr/local/apache2/htdocs
COPY ./load.pl /usr/local/apache2/htdocs
COPY ./store.pl /usr/local/apache2/htdocs
COPY ./burst_store.pl /usr/local/apache2/htdocs
COPY ./online_check.pl /usr/local/apache2/htdocs
COPY ./.htaccess /usr/local/apache2/htdocs
# Replace existing shebang line with this image's perl location.
RUN sed -i '1c#!/usr/bin/perl' /usr/local/apache2/htdocs/load.pl
RUN sed -i '1c#!/usr/bin/perl' /usr/local/apache2/htdocs/store.pl
RUN sed -i '1c#!/usr/bin/perl' /usr/local/apache2/htdocs/burst_store.pl
RUN sed -i '1c#!/usr/bin/perl' /usr/local/apache2/htdocs/online_check.pl
RUN mkdir /usr/local/apache2/htdocs/obf
COPY ./obf/.htaccess /usr/local/apache2/htdocs/obf
# Make sure our scripts are executable.
RUN chmod +x /usr/local/apache2/htdocs/*.pl
# Install perl modules
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
