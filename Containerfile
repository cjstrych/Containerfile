FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

# Install Apache and PHP
RUN dnf install -y httpd php && \
    dnf clean all

# Suppress ServerName warning
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Ensure directories exist and are writable by any UID with group 0
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Copy your app (optional)
# COPY ./src/ /var/www/html/

# Expose Apache port
EXPOSE 80

# Start Apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
