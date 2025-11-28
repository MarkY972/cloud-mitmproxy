# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory to /app
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application's code into the container at /app
COPY ./app .

# Expose port 8080 to the outside world
EXPOSE 8080

# Run migrations and then start the application
CMD yoyo apply --database "$DATABASE_URL" && uvicorn main:app --host 0.0.0.0 --port 8080
