#!/bin/bash

# php include inclue
# ppenssl
# pere

# php8.1-common include
# ctype
# fileinfo
# pdo
# tokenizer
# xml

# php8.1-json is a virtual package provided by php8.1-cli

apt install -y software-properties-common
add-apt-repository ppa:ondrej/php -y

apt install -y \
    php8.1 \
    php8.1-cli \
    php8.1-common \
    php8.1-bcmath \
    php8.1-curl \
    php8.1-dom \
    php8.1-mbstring \
    php8.1-redis \
    php8.1-swoole