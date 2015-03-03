#!/bin/bash
set -x
# This file: https://github.com/sammcj/docker-utils/blob/master/apt-settings.sh

# Set to AU mirror - change this if you like
sed -i 's/http.debian.net\/debian/mirror.internode.on.net\/pub\/debian/g' /etc/apt/*.list
sed -i 's/http.debian.net\/debian/mirror.internode.on.net\/pub\/debian/g' /etc/apt/sources.list.d/*.list

# Enable additional repos
sed -i 's/jessie main/jessie main contrib non-free/g' /etc/apt/sources.list
