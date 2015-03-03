#!/bin/bash
set -x
# Taken from https://raw.githubusercontent.com/docker/docker/master/contrib/mkimage/debootstrap
# https://github.com/sammcj/docker-utils/blob/master/apt-settings.sh

# Set to AU mirror - change this if you like
sed -i 's/http.debian.net\/debian/mirror.internode.on.net\/pub\/debian/g' /etc/apt/*.list
sed -i 's/http.debian.net\/debian/mirror.internode.on.net\/pub\/debian/g' /etc/apt/sources.list.d/*.list

# Enable additional repos
sed -i 's/jessie main/jessie main contrib non-free/g' /etc/apt/sources.list

# This file is one APT creates to make sure we don't "autoremove" our currently
# in-use kernel, which doesn't really apply to debootstraps/Docker images that
# don't even have kernels installed
rm -f "$rootfsDir/etc/apt/apt.conf.d/01autoremove-kernels"

# _keep_ us lean by effectively running "apt-get clean" after every install
aptGetClean='"rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true";'
echo >&2 "+ cat > '$rootfsDir/etc/apt/apt.conf.d/docker-clean'"
cat > "$rootfsDir/etc/apt/apt.conf.d/docker-clean" <<-EOF
	# Since for most Docker users, package installs happen in "docker build" steps,
	# they essentially become individual layers due to the way Docker handles
	# layering, especially using CoW filesystems.  What this means for us is that
	# the caches that APT keeps end up just wasting space in those layers, making
	# our layers unnecessarily large (especially since we'll normally never use
	# these caches again and will instead just "docker build" again and make a brand
	# new image).

	# Ideally, these would just be invoking "apt-get clean", but in our testing,
	# that ended up being cyclic and we got stuck on APT's lock, so we get this fun
	# creation that's essentially just "apt-get clean".
	DPkg::Post-Invoke { ${aptGetClean} };
	APT::Update::Post-Invoke { ${aptGetClean} };

	Dir::Cache::pkgcache "";
	Dir::Cache::srcpkgcache "";

	# Note that we do realize this isn't the ideal way to do this, and are always
	# open to better suggestions (https://github.com/docker/docker/issues).
EOF

# remove apt-cache translations for fast "apt-get update"
echo >&2 "+ echo Acquire::Languages 'none' > '$rootfsDir/etc/apt/apt.conf.d/docker-no-languages'"
cat > "$rootfsDir/etc/apt/apt.conf.d/docker-no-languages" <<-'EOF'
# In Docker, we don't often need the "Translations" files, so we're just wasting
# time and space by downloading them, and this inhibits that.  For users that do
# need them, it's a simple matter to delete this file and "apt-get update". :)

Acquire::Languages "none";
EOF

echo >&2 "+ echo Acquire::GzipIndexes 'true' > '$rootfsDir/etc/apt/apt.conf.d/docker-gzip-indexes'"
cat > "$rootfsDir/etc/apt/apt.conf.d/docker-gzip-indexes" <<-'EOF'
# Since Docker users using "RUN apt-get update && apt-get install -y ..." in
# their Dockerfiles don't go delete the lists files afterwards, we want them to
# be as small as possible on-disk, so we explicitly request "gz" versions and
# tell Apt to keep them gzipped on-disk.

# For comparison, an "apt-get update" layer without this on a pristine
# "debian:wheezy" base image was "29.88 MB", where with this it was only
# "8.273 MB".

Acquire::GzipIndexes "true";
Acquire::CompressionTys::Order:: "gz";
EOF

# Update everything
apt-get update && apt-get upgrade -qq

# Delete all the apt list files since they're big and get stale quickly
# This forces "apt-get update" in dependent images, which is also good
# rm -rf "$rootfsDir/var/lib/apt/lists"/*

# Final cleanup
apt-get -qq autoremove && apt-get clean
