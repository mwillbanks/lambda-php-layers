FROM public.ecr.aws/awsguru/devel

COPY --from=public.ecr.aws/awsguru/nginx /opt /opt
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.7.0 /lambda-adapter /opt/extensions/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

ENV PHP_VERSION="5.6.40"

RUN cd /tmp && \
    curl -O https://www.php.net/distributions/php-$PHP_VERSION.tar.gz && \
    tar -zxf php-$PHP_VERSION.tar.gz && \
    cd php-$PHP_VERSION && \
    ./buildconf --force && \
    ./configure \
      --bindir=/opt/php/bin \
      --docdir=/tmp \
      --dvidir=/tmp \
      --enable-bcmath=shared \
      --enable-calendar=shared \
      --enable-cli=shared \
      --enable-ctype=shared \
      --enable-dom=shared \
      --enable-exif=shared \
      --enable-fileinfo=shared \
      --enable-filter=shared \
      --enable-fpm=shared \
      --enable-ftp=shared \
      --enable-gd=shared \
      --enable-intl=shared \
      --enable-mbstring=shared \
      --enable-mysqlnd=shared \
      --enable-opcache=shared \
      --enable-pcntl=shared \
      --enable-pdo=shared \
      --enable-phar=shared \
      --enable-posix=shared \
      --enable-session=shared \
      --enable-shared=yes \
      --enable-shmop=shared \
      --enable-simplexml=shared \
      --enable-soap=shared \
      --enable-sockets=shared \
      --enable-sysvsem=shared\
      --enable-sysvshm=shared \
      --enable-tokenizer=shared\
      --enable-xml=shared \
      --enable-xmlreader=shared \
      --enable-xmlwriter=shared \
      --htmldir=/tmp \
      --localstatedir=/tmp \
      --mandir=/tmp \
      --pdfdir=/tmp \
      --prefix=/opt/php \
      --psdir=/tmp \
      --sbindir=/opt/php/bin \
      --with-bz2=shared \
      --with-config-file-path=/opt/php \
      --with-config-file-scan-dir=/opt/php/php.d \
      --with-curl=shared \
      --with-external-pcre=shared \
      --with-fpm-group=nobody \
      --with-fpm-user=nobody \
      --with-gettext=shared \
      --with-iconv=shared \
      --with-libedit=shared \
      --with-libxml=shared \
      --with-mysql=shared \
      --with-mysqli=shared \
      --with-openssl=shared \
      --with-pdo-mysql=shared \
      --with-pdo-pgsql=shared \
      --with-pdo-sqlite=shared \
      --with-pear=shared \
      --with-pgsql=shared \
      --with-readline=shared \
      --with-xmlrpc=shared \
      --with-xsl=shared \
      --with-zip=shared \
      --with-zlib=shared \
      && \
    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
    make install && \
    for bin in $(ls /opt/php/bin); do \
        ln -s /opt/php/bin/$bin /usr/bin ; \
    done && \
    \
    ln -s /opt/nginx/bin/nginx /usr/bin && \
    \
    /lambda-layer change_ext_dir && \
    /lambda-layer php_enable_extensions && \
    \
#    cd /tmp && \
#    git clone --recursive --branch v1.2.1 https://github.com/awslabs/aws-crt-php.git && \
#    cd aws-crt-php &&  \
#    phpize && \
#    ./configure && \
#    make -j$(cat /proc/cpuinfo | grep "processor" | wc -l) && \
#    make install && \
#    \
    /lambda-layer php_enable_extensions && \
    /lambda-layer php_copy_libs && \
    \
    echo 'Clean Cache' && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    rm -rf /tmp/*

# config files
ADD nginx/conf/nginx.conf      /opt/nginx/conf/nginx.conf
ADD php/php.ini                /opt/php/php.ini
ADD php/etc/php-fpm.conf       /opt/php/etc/php-fpm.conf
ADD mysql/my.cnf               /etc/my.cnf
ADD mysql/my.cnf               /opt/mysql/my.cnf

# code files
COPY app /var/task/app

COPY runtime/bootstrap /opt/bootstrap

# Copy files to /var/runtime to support deploying as a Docker image
COPY runtime/bootstrap /var/runtime/bootstrap

RUN chmod 0755 /opt/bootstrap  \
    && chmod 0755 /var/runtime/bootstrap

ENTRYPOINT /var/runtime/bootstrap
