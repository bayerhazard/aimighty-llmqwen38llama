# llama-server (spiritbuun/buun-llama-cpp) for Olares One
# Core Ultra 9 275HX (AVX-512, AMX) + RTX 5090 (sm_120 Blackwell)
# Builds master at pinned commit, pushes to ghcr.io/bayerhazard/buun-llama-cpp:<shortsha>

# ---- Stage 1: Build ----
FROM nvidia/cuda:13.1.1-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build git ca-certificates pkg-config \
    libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ARG PIN=283ba19eda82d18e93c44ced5efcf3da0494b83d

ENV CUDA_HOME=/usr/local/cuda
ENV PATH=/usr/local/cuda/bin:${PATH}

WORKDIR /build
RUN git clone https://github.com/spiritbuun/buun-llama-cpp.git && \
    cd buun-llama-cpp && git checkout ${PIN} && git rev-parse HEAD

WORKDIR /build/buun-llama-cpp
RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CUDA=ON \
    -DGGML_CUDA_FA=ON \
    -DCMAKE_CUDA_ARCHITECTURES=120 \
    -DGGML_AVX=ON \
    -DGGML_AVX2=ON \
    -DGGML_AVX512=ON \
    -DGGML_AVX512_VBMI=ON \
    -DGGML_AVX512_VNNI=ON \
    -DGGML_AVX512_BF16=ON \
    -DGGML_AMX_TILE=ON \
    -DGGML_AMX_INT8=ON \
    -DGGML_AMX_BF16=ON \
    -DGGML_FMA=ON \
    -DGGML_F16C=ON \
    -DLLAMA_OPENSSL=ON \
    -DLLAMA_CURL=OFF \
    -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -Wl,-rpath-link,/usr/local/cuda/lib64/stubs" \
    -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -Wl,-rpath-link,/usr/local/cuda/lib64/stubs" \
    && cmake --build build --config Release -j$(nproc) --target llama-server

# ---- Stage 2: Runtime (mirrors aamsellem/buun-llama-cpp layout) ----
FROM nvidia/cuda:13.1.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 ca-certificates curl bash \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/buun-llama-cpp/build/bin/llama-server /app/llama-server
COPY --from=builder /build/buun-llama-cpp/build/bin/*.so* /app/

ENV LD_LIBRARY_PATH=/app
ENTRYPOINT ["/app/llama-server"]
