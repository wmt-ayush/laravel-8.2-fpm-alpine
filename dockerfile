# Use PHP 8.2 with Alpine 3.16 base image
FROM php:8.2-fpm-alpine3.16

LABEL Maintainer="Ayush Chaturvedi <ayushc@webmobtech.com>" \
      Description="Nginx + PHP8.2-FPM-Alpine Based on Ubuntu 22.04."

# Set timezone to UTC
RUN echo "UTC" > /etc/timezone

# Install essential packages
RUN apk add --no-cache zip unzip openrc curl nano sqlite nginx supervisor

# Add Alpine repositories (main and community)
RUN rm -f /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/main" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/community" >> /etc/apk/repositories

# Install build dependencies for PHP extensions
RUN apk add --no-cache --virtual .build-deps \
    zlib-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    bzip2-dev \
    libzip-dev

# Install PHP 8.2 production dependencies
RUN apk add --update --no-cache --virtual \
    php8.2-mbstring \
    php8.2-fpm \
    php8.2-mysqli \
    php8.2-opcache \
    php8.2-phar \
    php8.2-xml \
    php8.2-zip \
    php8.2-zlib \
    php8.2-pdo \
    php8.2-tokenizer \
    php8.2-session \
    php8.2-pdo_mysql \
    php8.2-pdo_sqlite \
    mysql-client \
    dcron \
    jpegoptim \
    pngquant \
    optipng \
    icu-dev \
    freetype-dev

# Configure and install PHP extensions
RUN docker-php-ext-configure opcache --enable-opcache && \
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

# Check installed PHP modules
RUN php -m

# Install Composer
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Set Composer environment variable and PATH
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PATH="./vendor/bin:$PATH"

# Copy custom PHP configurations
COPY opcache.ini $PHP_INI_DIR/conf.d/
COPY php.ini $PHP_INI_DIR/conf.d/

# Set up Cron and Supervisor by default
RUN echo '*  *  *  *  * /usr/local/bin/php /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && mkdir /etc/supervisor.d
ADD master.ini /etc/supervisor.d/
ADD default.conf /etc/nginx/conf.d/
ADD nginx.conf /etc/nginx/

# Remove build dependencies to reduce image size
RUN apk del -f .build-deps

# Set working directory
WORKDIR /var/www/html

# Set the default command to start supervisord
CMD ["/usr/bin/supervisord"]
