FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

RUN dnf install -y httpd php && \
    dnf clean all

# Fix Apache port and ServerName
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Redirect logs to writable directory
RUN mkdir -p /tmp/httpd-logs && \
    chown -R 1001:0 /tmp/httpd-logs && \
    chmod -R g+rwX /tmp/httpd-logs && \
    sed -i 's|ErrorLog "logs/error_log"|ErrorLog "/tmp/httpd-logs/error_log"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|CustomLog "logs/access_log"|CustomLog "/tmp/httpd-logs/access_log" common|' /etc/httpd/conf/httpd.conf

# Fix permissions for runtime dirs
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

EXPOSE 8080

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
