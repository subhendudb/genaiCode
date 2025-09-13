# Use an official Python image as the base
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set work directory
WORKDIR /app

# Create a non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Install system dependencies
RUN apt-get update && \
    apt-get install --no-install-recommends -y gcc libpq-dev build-essential curl && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip==23.3.1 && pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Change ownership of the app directory to the appuser
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose the port Flask runs on
EXPOSE 5000

# Set environment variables for Flask
ENV FLASK_APP=app.py

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:5000/health || exit 1

# Default command to run the Flask app
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
