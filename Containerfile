FROM registry.access.redhat.com/ubi9/ubi

# Install PHP 8.2, Apache, and other dependencies
RUN dnf -y module enable php:8.2 && \
    dnf -y install git httpd php php-fpm vim && \
    dnf clean all

# Create required directories with proper permissions
RUN mkdir -p /run/php-fpm/ && \
    mkdir -p /var/www/html && \
    mkdir -p /var/log/httpd && \
    mkdir -p /var/run/httpd && \
    mkdir -p /tmp/httpd

# Create phpinfo.php file
RUN echo '<?php' > /var/www/html/phpinfo.php && \
    echo '' >> /var/www/html/phpinfo.php && \
    echo '// SHOW ALL INFORMATION, DEFAULTS TO INFO_ALL' >> /var/www/html/phpinfo.php && \
    echo 'phpinfo();' >> /var/www/html/phpinfo.php && \
    echo '' >> /var/www/html/phpinfo.php && \
    echo '// SHOW JUST THE MODULE INFORMATION.' >> /var/www/html/phpinfo.php && \
    echo '// PHPINFO(8) YIELDS IDENTICAL RESULTS.' >> /var/www/html/phpinfo.php && \
    echo 'phpinfo(INFO_MODULES);' >> /var/www/html/phpinfo.php && \
    echo '' >> /var/www/html/phpinfo.php && \
    echo '?>' >> /var/www/html/phpinfo.php

# Configure Apache for OpenShift (non-root user)
RUN sed -i 's/^Listen 80$/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/^#ServerName.*/ServerName localhost:8080/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/^User apache$/User 1001/' /etc/httpd/conf/httpd.conf && \
    sed -i 's/^Group apache$/Group 0/' /etc/httpd/conf/httpd.conf && \
    sed -i 's|^DocumentRoot "/var/www/html"|DocumentRoot "/var/www/html"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|^<Directory "/var/www/html">|<Directory "/var/www/html">|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|^ErrorLog logs/error_log|ErrorLog /dev/stderr|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|^CustomLog logs/access_log|CustomLog /dev/stdout|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|^PidFile /run/httpd/httpd.pid|PidFile /tmp/httpd/httpd.pid|' /etc/httpd/conf/httpd.conf

# Configure PHP-FPM for OpenShift
RUN sed -i 's/^user = apache$/user = 1001/' /etc/php-fpm.d/www.conf && \
    sed -i 's/^group = apache$/group = 0/' /etc/php-fpm.d/www.conf && \
    sed -i 's|^listen = /run/php-fpm/www.sock|listen = 127.0.0.1:9000|' /etc/php-fpm.d/www.conf && \
    sed -i 's/^;listen.owner = nobody$/listen.owner = 1001/' /etc/php-fpm.d/www.conf && \
    sed -i 's/^;listen.group = nobody$/listen.group = 0/' /etc/php-fpm.d/www.conf && \
    sed -i 's|^pid = /run/php-fpm/php-fpm.pid|pid = /tmp/php-fpm.pid|' /etc/php-fpm.conf

# Set proper permissions for OpenShift random user ID
RUN chgrp -R 0 /var/www/html /var/log/httpd /var/run/httpd /tmp/httpd /run/php-fpm /etc/httpd /etc/php-fpm.d /etc/php-fpm.conf && \
    chmod -R g+rwX /var/www/html /var/log/httpd /var/run/httpd /tmp/httpd /run/php-fpm /etc/httpd /etc/php-fpm.d /etc/php-fpm.conf

# Create a startup script to run both php-fpm and httpd
RUN echo '#!/bin/bash' > /start.sh && \
    echo '# Start PHP-FPM in background' >> /start.sh && \
    echo 'php-fpm &' >> /start.sh && \
    echo '# Start Apache in foreground' >> /start.sh && \
    echo 'httpd -D FOREGROUND' >> /start.sh

RUN chmod +x /start.sh && \
    chgrp 0 /start.sh && \
    chmod g+rwx /start.sh

# Use non-root user (OpenShift will assign random UID in root group)
USER 1001

# Expose port 8080 (non-privileged port)
EXPOSE 8080

# Start both services
CMD ["/start.sh"]
