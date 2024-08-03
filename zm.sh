#!/bin/bash

cat > /etc/locale.gen <<EOF1
en_GB ISO-8859-1
en_GB.ISO-8859-15 ISO-8859-15
en_GB.UTF-8 UTF-8
EOF1

cat > /etc/default/locale <<EOF2
LC_ALL=en_GB.UTF-8
LANG=en_GB.UTF-8
EOF2

locale-gen 
cat > /etc/apt/sources.list <<EOFSRC

deb http://deb.debian.org/debian bookworm contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-updates contrib main non-free-firmware
deb http://deb.debian.org/debian bookworm-backports contrib main non-free-firmware
deb http://deb.debian.org/debian-security bookworm-security contrib main non-free-firmware
EOFSRC

apt-get update

deluser --remove-all-files pi
apt-get update
timedatectl set-timezone  Europe/London
date
apt install -y  apache2 mariadb-server php libapache2-mod-php php-mysql lsb-release gnupg2
sed -i 's*;date.timezone =*date.timezone = Europe/London*g' /etc/php/8.2/apache2/php.ini
systemctl restart apache2
apt install -y zoneminder
mysql -uroot < /usr/share/zoneminder/db/zm_create.sql
mysql -uroot  -e "grant all on zm.* to 'zmuser'@localhost identified by 'zmpass';"
mysqladmin -uroot  reload
chmod 640 /etc/zm/zm.conf
chown root:www-data /etc/zm/zm.conf
chown -R www-data:www-data /var/cache/zoneminder/
chmod 755 /var/cache/zoneminder/
mv /etc/apache2/conf-available/zoneminder.conf /etc/apache2/conf-available/zoneminder.conf.sav
cat > /etc/apache2/conf-available/zoneminder.conf <<EOF
# Remember to enable cgi mod (i.e. "a2enmod cgi").
ScriptAlias /zm/cgi-bin "/usr/lib/zoneminder/cgi-bin"
<Directory "/usr/lib/zoneminder/cgi-bin">
    Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
    AllowOverride All
    Require all granted
</Directory>


# Order matters. This alias must come first.
Alias /zm/cache "/var/cache/zoneminder"
<Directory "/var/cache/zoneminder">
    Options -Indexes +FollowSymLinks
    AllowOverride None
    <IfModule mod_authz_core.c>
        # Apache 2.4
        Require all granted
    </IfModule>
</Directory>

Alias /zm /usr/share/zoneminder/www
<Directory /usr/share/zoneminder/www>
  Options -Indexes +FollowSymLinks
  <IfModule mod_dir.c>
    DirectoryIndex index.php
  </IfModule>
</Directory>

# For better visibility, the following directives have been migrated from the
# default .htaccess files included with the CakePHP project.
# Parameters not set here are inherited from the parent directive above.
<Directory "/usr/share/zoneminder/www/api">
   RewriteEngine on
   RewriteRule ^$ app/webroot/ [L]
   RewriteRule (.*) app/webroot/$1 [L]
   RewriteBase /zm/api
</Directory>

<Directory "/usr/share/zoneminder/www/api/app">
   RewriteEngine on
   RewriteRule ^$ webroot/ [L]
   RewriteRule (.*) webroot/$1 [L]
   RewriteBase /zm/api
</Directory>

<Directory "/usr/share/zoneminder/www/api/app/webroot">
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
    RewriteBase /zm/api
</Directory>


EOF

systemctl enable zoneminder.service
adduser www-data video
systemctl start zoneminder.service
a2enconf zoneminder
a2enmod rewrite
a2enmod headers
a2enmod expires
a2enmod cgi
systemctl restart apache2
exit
