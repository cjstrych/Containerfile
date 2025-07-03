FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

RUN dnf install -y httpd php && \
    dnf clean all

# Fix: Listen on port 8080 instead of 80
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Permissions for OpenShift
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Expose new non-root port
EXPOSE 8080

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
