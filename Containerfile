FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP-FPM"
LABEL name="ubi9-apache-php"
LABEL version="1.0"
LABEL description="UBI9-based image running Apache with PHP-FPM for OpenShift-compatible containers."

# Install Apache, PHP, and PHP-FPM
RUN dnf install -y httpd php php-cli php-fpm php-mysqlnd php-pdo php-common && \
    dnf clean all && rm -rf /var/cache/dnf

# Change Apache to listen on port 8080
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Avoid Apache warnings
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Configure Apache to proxy PHP to php-fpm
RUN echo '<FilesMatch \.php$>\n\
    SetHandler "proxy:fcgi://localhost:9000"\n\
</FilesMatch>' > /etc/httpd/conf.d/php-fpm.conf

# Set DirectoryIndex to use index.php first
RUN sed -i 's/^DirectoryIndex .*/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

# Writable log dir for OpenShift
RUN mkdir -p /tmp/httpd && \
    chown -R 1001:0 /tmp/httpd && \
    chmod -R g+rwX /tmp/httpd

# Sample PHP page
RUN echo '<?php echo "Hello from PHP-FPM!"; ?>' > /var/www/html/index.php

# Remove index.html to force PHP page
RUN rm -f /var/www/html/index.html

# Redirect logs to writable OpenShift path
RUN sed -i 's|ErrorLog "logs/error_log"|ErrorLog "/tmp/httpd/error_log"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|CustomLog "logs/access_log" combined|CustomLog "/tmp/httpd/access_log" common|' /etc/httpd/conf/httpd.conf

# Ensure writable dirs for OpenShift
RUN mkdir -p /run/httpd /var/www/html /run/php-fpm && \
    chown -R 1001:0 /run/httpd /var/www /run/php-fpm && \
    chmod -R g+rwX /run/httpd /var/www /run/php-fpm

# Expose non-root port
EXPOSE 8080

# Switch to non-root user (OpenShift-compatible)
USER 1001

# Run both Apache and PHP-FPM in foreground using dumb-init or bash workaround
CMD /bin/bash -c "/usr/sbin/php-fpm --nodaemonize & /usr/sbin/httpd -D FOREGROUND"
