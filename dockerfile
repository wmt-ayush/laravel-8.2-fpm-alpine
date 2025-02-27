# Use PHP 8.2 with Alpine base image
FROM php:8.2-fpm-alpine

# Set timezone to UTC
RUN echo "UTC" > /etc/timezone

# Install essential packages
RUN apk add --no-cache zip unzip openrc curl nano sqlite nginx supervisor

# Add Alpine repositories
RUN rm -f /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/main" > /etc/apk/repositories && \
    echo "https://dl-cdn.alpinelinux.org/alpine/v3.18/community" >> /etc/apk/repositories

# Install build dependencies and required packages for PHP extensions
RUN apk update && apk upgrade && apk add --no-cache \
    linux-headers \
    zlib-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libxml2-dev \
    bzip2-dev \
    libzip-dev \
    icu-dev \
    freetype-dev \
    mysql-client \
    dcron \
    jpegoptim \
    pngquant \
    optipng \
    oniguruma-dev

# Configure PHP extensions
RUN docker-php-ext-configure opcache --enable-opcache && \
    docker-php-ext-configure gd --with-jpeg=/usr/include/ --with-freetype=/usr/include/ && \
    docker-php-ext-configure zip

# Install PHP extensions (only once)
RUN docker-php-ext-install \
    mysqli \
    pdo \
    pdo_mysql \
    zip \
    opcache \
    xml \
    sockets \
    intl \
    gd \
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

# Set working directory
WORKDIR /var/www/

# Set the default command to start supervisord
CMD ["/usr/bin/supervisord"]
