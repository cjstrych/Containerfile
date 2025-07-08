FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"

# Install Apache and PHP-FPM
RUN dnf install -y httpd php php-fpm && \
    dnf clean all

# Configure Apache to proxy PHP to php-fpm (on TCP)
RUN echo '<FilesMatch \.php$>\n\
    SetHandler "proxy:fcgi://127.0.0.1:9000"\n\
</FilesMatch>' > /etc/httpd/conf.d/php-fpm.conf

# Set Apache to listen on port 8080 (non-root)
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Add PHP test page
RUN echo "<?php echo 'Hello from PHP-FPM!'; ?>" > /var/www/html/index.php

# Make required directories for PHP-FPM and Apache
RUN mkdir -p /run/httpd /run/php-fpm /tmp/httpd && \
    chown -R 1001:0 /run/httpd /run/php-fpm /tmp/httpd /var/www && \
    chmod -R g+rwX /run/httpd /run/php-fpm /tmp/httpd /var/www

# Expose HTTP port
EXPOSE 8080

# Use OpenShift-compatible non-root UID
USER 1001

# Start both services in foreground
CMD /bin/bash -c "/usr/sbin/php-fpm --nodaemonize & /usr/sbin/httpd -D FOREGROUND"
