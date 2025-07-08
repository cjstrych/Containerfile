FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP-FPM for OpenShift/Podman"

# Install Apache and PHP-FPM
RUN dnf install -y httpd php php-fpm && dnf clean all

# Configure Apache to listen on 8080 (non-root port)
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Proper php-fpm proxy config with closed FilesMatch
RUN echo '<FilesMatch \.php$>\n    SetHandler "proxy:fcgi://127.0.0.1:9000"\n</FilesMatch>' \
    > /etc/httpd/conf.d/php-fpm.conf

# Create PHP test page
RUN echo "<?php echo 'Hello from PHP-FPM!'; ?>" > /var/www/html/index.php

# Prepare writable directories for OpenShift non-root UID (1001)
RUN mkdir -p /run/httpd /run/php-fpm /tmp/httpd && \
    chown -R 1001:0 /run/httpd /run/php-fpm /tmp/httpd /var/www && \
    chmod -R g+rwX /run/httpd /run/php-fpm /tmp/httpd /var/www

# Expose port 8080
EXPOSE 8080

# Switch to OpenShift-compatible user
USER 1001

# Start PHP-FPM and Apache together in foreground
CMD /bin/bash -c "/usr/sbin/php-fpm --nodaemonize & /usr/sbin/httpd -D FOREGROUND"
