FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

# Install Apache and PHP
RUN dnf install -y git httpd php && \
    dnf clean all

# Change Apache to listen on non-privileged port 8080
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Set ServerName to avoid warnings
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Create a writable log directory for OpenShift (non-root UID)
RUN mkdir -p /tmp/httpd && \
    chown -R 1001:0 /tmp/httpd && \
    chmod -R g+rwX /tmp/httpd

# Set DirectoryIndex to include index.php
RUN sed -i 's/^DirectoryIndex .*/DirectoryIndex index.html index.php/' /etc/httpd/conf/httpd.conf

# Add example index.php and index.html (optional for testing)
RUN echo '<?php echo "Hello from PHP!"; ?>' > /var/www/html/index.php && \
    echo '<html><body><h1>Hello from HTML!</h1></body></html>' > /var/www/html/index.html

# Redirect ErrorLog and CustomLog to writable /tmp/httpd directory
RUN sed -i 's|ErrorLog "logs/error_log"|ErrorLog "/tmp/httpd/error_log"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|CustomLog "logs/access_log" combined|CustomLog "/tmp/httpd/access_log" common|' /etc/httpd/conf/httpd.conf

# Ensure Apache runtime directories are writable
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Expose the non-root port
EXPOSE 8080

# Start Apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
