# Use an official Python runtime as a parent image
FROM python:3.8-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Install additional dependencies for SPrediXcan
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install SPrediXcan
RUN git clone https://github.com/hakyimlab/MetaXcan.git && \
    cd MetaXcan/software && \
    python setup.py install

# Set the entrypoint to the SPrediXcan script
ENTRYPOINT ["python", "/app/MetaXcan/software/SPrediXcan.py"]
