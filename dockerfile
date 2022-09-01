FROM php:8.0-fpm-alpine3.16

# Essentials
RUN echo "UTC" > /etc/timezone
RUN apk add --no-cache zip unzip openrc curl nano sqlite nginx supervisor


# Add Repositories
RUN rm -f /etc/apk/repositories &&\
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/community" >> /etc/apk/repositories

# Add Build Dependencies
RUN apk add --no-cache --virtual .build-deps  \
    zlib-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    bzip2-dev \
    libzip-dev


# Add Production Dependencies
RUN apk add --update --no-cache --virtual \
    php8-mbstring \
    php8-fpm \
    php8-mysqli \
    php8-opcache \
    # php8-pecl-redis \
    php8-phar \
    php8-xml \
    # php8-xmlreader \
    php8-zip \
    php8-zlib \
    php8-pdo \
    # php8-xmlwriter \
    php8-tokenizer \
    php8-session \
    php8-pdo_mysql \
    php8-pdo_sqlite \
    mysql-client \
    dcron \
    jpegoptim \
    pngquant \
    optipng \
    icu-dev \
    freetype-dev 

# Configure & Install Extension
RUN docker-php-ext-configure \
    opcache --enable-opcache &&\
    docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ && \
    docker-php-ext-configure zip && \
    docker-php-ext-install \
    opcache \
    mysqli \
    pdo \
    pdo_mysql \
    sockets \
    intl \
    gd \
    xml \
    bz2 \
    pcntl \
    bcmath

# Install modules
RUN php -m


# Add Composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
#RUN composer global require hirak/prestissimo
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

COPY opcache.ini $PHP_INI_DIR/conf.d/
COPY php.ini $PHP_INI_DIR/conf.d/

# Setup Crond and Supervisor by default
RUN echo '*  *  *  *  * /usr/local/bin/php  /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && mkdir /etc/supervisor.d
ADD master.ini /etc/supervisor.d/
ADD default.conf /etc/nginx/conf.d/

# Remove Build Dependencies
RUN apk del -f .build-deps
# Setup Working Dir
WORKDIR /var/www/html

CMD ["/usr/bin/supervisord"]
