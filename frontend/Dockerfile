# Use an official Node.js image to build the app
FROM node:18

# Set working directory
WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && apt-get install --no-install-recommends -y curl && rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app's source code
COPY . .

# Change ownership of the app directory to the appuser
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 8080

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1
# The build artifacts will be in /app/build
# No CMD needed, as this image is just for building

# Optionally, you can set the default command to list the build directory
CMD ["npm", "start"]
