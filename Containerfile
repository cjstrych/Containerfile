FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"
LABEL name="ubi9-apache-php"
LABEL version="1.0"
LABEL description="A minimal Apache + PHP image based on Red Hat UBI9 for use on OpenShift or other container platforms."

# Install Apache and PHP with mod_php
RUN dnf install -y git httpd php php-cli php-common mod_php && \
    dnf clean all && rm -rf /var/cache/dnf

# Change Apache to listen on non-privileged port 8080
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Set ServerName to avoid warnings
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Ensure Apache knows how to handle .php files
RUN echo '<FilesMatch \.php$>\n    SetHandler application/x-httpd-php\n</FilesMatch>' > /etc/httpd/conf.d/php.conf

# Set DirectoryIndex to prioritize index.php
RUN sed -i 's/^DirectoryIndex .*/DirectoryIndex index.php index.html/' /etc/httpd/conf/httpd.conf

# Create a writable log directory for OpenShift (non-root UID)
RUN mkdir -p /tmp/httpd && \
    chown -R 1001:0 /tmp/httpd && \
    chmod -R g+rwX /tmp/httpd

# Add example index.php (working PHP test page)
RUN echo '<?php echo "Hello from PHP!"; ?>' > /var/www/html/index.php

# Remove index.html to ensure index.php is served
RUN rm -f /var/www/html/index.html

# Redirect logs to writable directory
RUN sed -i 's|ErrorLog "logs/error_log"|ErrorLog "/tmp/httpd/error_log"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|CustomLog "logs/access_log" combined|CustomLog "/tmp/httpd/access_log" common|' /etc/httpd/conf/httpd.conf

# Ensure Apache runtime directories are writable
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Expose non-root HTTP port
EXPOSE 8080

# Optional: Run as OpenShift-compatible non-root user
USER 1001

# Start Apache in the foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
