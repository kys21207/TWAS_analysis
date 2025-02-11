# Use an older Python base image that's known to work
FROM python:3.7.9-slim-buster

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV NPY_DISABLE_CPU_FEATURES=1
ENV PYTHONPATH=/app/MetaXcan/software
ENV PATH="/app:${PATH}"

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Make the process_gwas.sh script executable
RUN chmod +x /app/process_gwas.sh

# Install necessary system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libblas3 \
    liblapack3 \
    libatlas-base-dev \
    gfortran \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install specific versions of Python packages known to work together
RUN pip install --no-cache-dir \
    'numpy==1.16.6' \
    'scipy==1.2.3' \
    'pandas==0.25.3' \
    'sqlalchemy==1.3.24' \
    'patsy==0.5.2' \
    'statsmodels==0.10.2' \
    'h5py==2.10.0' \
    'bgen_reader==3.0.3' \
    'cyvcf2==0.30.15'

# Install SPrediXcan
RUN git clone https://github.com/hakyimlab/MetaXcan.git && \
    cd MetaXcan/software && \
    python setup.py install

# Set the entrypoint to the SPrediXcan script
ENTRYPOINT ["bash", "/app/process_gwas.sh"]

