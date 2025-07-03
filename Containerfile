FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

# Install Apache and PHP
RUN dnf install -y httpd php && \
    dnf clean all

# Set ServerName to avoid warning
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Fix permissions for OpenShift
RUN mkdir -p /run/httpd && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Force Apache to use non-root compatible user config
RUN echo "User apache\nGroup root" > /etc/httpd/conf.d/container-user.conf

# Set working directory
WORKDIR /var/www/html

# Expose default Apache port
EXPOSE 80

# Start Apache
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
