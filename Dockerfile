# Small Python base image (Debian slim) to keep the final image light
FROM python:3.11-slim

# Set working directory inside the container
WORKDIR /app

# Copy only dependency list first to leverage Docker layer caching
COPY src/requirements.txt .

# Install Python dependencies (no pip download cache in the image)
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY src/app.py .

# Copy secret environment  
COPY prod.cfg.age . 

# Document the port the app listens on
EXPOSE 5000

# Start the Flask app
CMD ["python", "app.py"]
