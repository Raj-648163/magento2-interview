FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    zip \
    curl \
    vim \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libxslt1-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev

RUN docker-php-ext-install \
    pdo_mysql \
    intl \
    zip \
    soap \
    xsl

RUN a2enmod rewrite

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
