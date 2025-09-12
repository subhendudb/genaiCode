# Use an official Node.js image to build the app
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the app's source code
COPY . .

EXPOSE 8080
# The build artifacts will be in /app/build
# No CMD needed, as this image is just for building

# Optionally, you can set the default command to list the build directory
CMD ["npm", "start"] 