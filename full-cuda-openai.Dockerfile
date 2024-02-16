ARG UBUNTU_VERSION=22.04

# This needs to generally match the container host's environment.
ARG CUDA_VERSION=11.7.1

# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} as build

# Unless otherwise specified, we make a fat build.
ARG CUDA_DOCKER_ARCH=all

RUN apt-get update && \
    apt-get install -y build-essential python3 python3-pip git

COPY requirements.txt   requirements.txt
COPY requirements       requirements

RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

WORKDIR /app

COPY . .

# Set nvcc architecture
ENV CUDA_DOCKER_ARCH=${CUDA_DOCKER_ARCH}
# Enable cuBLAS
ENV LLAMA_CUBLAS=1

RUN make

RUN pip install llama-cpp-python[server]

# ENTRYPOINT ["/app/.devops/tools.sh"]
# ENTRYPOINT ["python3 -m llama_cpp.server --model models/7B/llama-model.gguf --n_gpu_layers 35 --host 0.0.0.0 --port 8000"]
