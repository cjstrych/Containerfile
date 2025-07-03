# Use the UBI 9 base image
FROM registry.access.redhat.com/ubi9/ubi

# Set metadata (optional but good practice)
LABEL maintainer="you@example.com"
LABEL name="ubi9-httpd-php"
LABEL summary="Apache + PHP on UBI9"
LABEL description="A simple Apache and PHP setup on UBI9 base."

# Install Apache and PHP
RUN dnf install -y httpd php && \
    dnf clean all

# Copy app code (optional - can be added later)
# COPY ./src/ /var/www/html/

# Ensure permissions for OpenShift (non-root UID)
RUN chown -R 1001:0 /var/www && \
    chmod -R g+rwX /var/www

# Expose Apache's default port
EXPOSE 80

# Set working directory
WORKDIR /var/www/html

# Start Apache in the foreground (as required in containers)
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
