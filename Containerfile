FROM registry.access.redhat.com/ubi9/ubi

LABEL maintainer="you@example.com"
LABEL summary="UBI9 with Apache and PHP"

# Install Apache and PHP
RUN dnf install -y httpd php && \
    dnf clean all

# Change Apache to listen on non-privileged port 8080
RUN sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

# Set ServerName to avoid warnings
RUN echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

# Create a writable log directory for OpenShift (non-root UID)
RUN mkdir -p /tmp/httpd-logs && \
    chown -R 1001:0 /tmp/httpd-logs && \
    chmod -R g+rwX /tmp/httpd-logs

# Redirect ErrorLog and CustomLog to writable /tmp directory
RUN sed -i 's|ErrorLog "logs/error_log"|ErrorLog "/tmp/httpd-logs/error_log"|' /etc/httpd/conf/httpd.conf && \
    sed -i 's|CustomLog "logs/access_log" combined|CustomLog "/tmp/httpd-logs/access_log" common|' /etc/httpd/conf/httpd.conf

# Ensure Apache runtime directories are writable
RUN mkdir -p /run/httpd /var/www/html && \
    chown -R 1001:0 /run/httpd /var/www && \
    chmod -R g+rwX /run/httpd /var/www

# Expose the non-root port
EXPOSE 8080

# Start Apache in foreground
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
