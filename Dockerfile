FROM golang as configurability_php
MAINTAINER brian.wilkinson@1and1.co.uk
WORKDIR /go/src/github.com/1and1internet/configurability
RUN git clone https://github.com/1and1internet/configurability.git . \
        && make php\
        && echo "configurability php plugin successfully built"

FROM alpine as ioncube_loader
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/ioncube_loader \
	&& tar zxf ioncube_loader/ioncube_loaders_lin_x86-64.tar.gz

FROM alpine as php_debs
RUN apk add git \
	&& git -c http.sslVerify=false clone https://git.dev.glo.gb/cloudhostingpublic/legacy-php-build

FROM 1and1internet/debian-8-apache
MAINTAINER brian.wilkinson@fasthosts.com
ARG DEBIAN_FRONTEND=noninteractive
ARG PHPVER=7.0
COPY files /
COPY --from=php_debs /legacy-php-build/debs/${PHPVER}/*.deb /tmp/
COPY --from=configurability_php /go/src/github.com/1and1internet/configurability/bin/plugins/php.so /opt/configurability/goplugins

RUN \
    apt-get update && \
    apt-get install -y imagemagick graphicsmagick curl \
					   libc-client2007e libcurl3 libicu52 libjpeg62-turbo libmcrypt4 libtidy-0.99-0 libxslt1.1 \
					   libiconv-hook1 libldap-2.4-2 libmhash2 libodbc1 \
					   autoconf libtool libapache2-mod-fastcgi \
					   libpq5 libsnmp30 snmp-mibs-downloader libxmlrpc-epi0 librecode0 && \
    echo "PHP" && \
		dpkg -i /tmp/php${PHPVER}*.deb && \
		rm -f /tmp/php${PHPVER}*.deb && \
		update-alternatives --install /usr/bin/php php /usr/bin/php${PHPVER} 1 && \
		a2enmod proxy_fcgi fastcgi && \
	echo "APACHE" && \
    	sed -i -e 's/DirectoryIndex index.html index.cgi index.pl index.php index.xhtml index.htm/DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm/g' /etc/apache2/mods-available/dir.conf && \
	echo "COMPOSER" && \
		mkdir /tmp/composer/ && \
	    cd /tmp/composer && \
	    curl -sS https://getcomposer.org/installer | php && \
	    mv composer.phar /usr/local/bin/composer && \
	    chmod a+x /usr/local/bin/composer && \
	    cd / && \
	    rm -rf /tmp/composer && \
	echo "PECL packages" && \
		apt-get install -y libgpgme11-dev make pkg-config libmagickwand-dev libssl-dev && \
		chmod 777 /usr/lib/php/${PHPVER} && \
		pecl channel-update pecl.php.net && \
		pecl install gnupg && \
		yes '' | pecl install imagick && \
		yes '' | pecl install mongodb && \
    apt-get remove -y curl autoconf libtool make pkg-config libmagickwand-dev libssl-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    chmod 777 -R /var/www  && \
    apache2ctl -t && \
    mkdir -p /run /var/lib/apache2 /var/lib/php && \
    chmod -R 777 /run /var/lib/apache2 /var/lib/php /etc/php/${PHPVER}/php.ini

COPY --from=ioncube_loader /ioncube/ioncube_loader_lin_${PHPVER}.so /usr/lib/php/${PHPVER}/extensions
