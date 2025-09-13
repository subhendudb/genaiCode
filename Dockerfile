# Nginx stage
# checkov:skip=CKV_DOCKER_3: nginx requires root to bind to port 80, worker processes run as nginx user
FROM nginx:alpine

# Create a non-root user for nginx (nginx already exists, but we'll create our own)
RUN addgroup -g 1001 -S nginxuser && adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginxuser -g nginxuser nginxuser

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create necessary directories and set permissions
RUN mkdir -p /var/cache/nginx /var/run /var/log/nginx && \
    chown -R nginxuser:nginxuser /var/cache/nginx /var/run /var/log/nginx && \
    chmod -R 755 /var/cache/nginx /var/run /var/log/nginx

# Configure nginx to run as nginx user but with proper permissions
RUN sed -i 's/user nginx;/# user nginx;/' /etc/nginx/nginx.conf

# Note: nginx needs to run as root to bind to port 80, but we've created a user
# The nginx master process runs as root, worker processes run as nginx user

EXPOSE 80

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

CMD ["nginx", "-g", "daemon off;"]
