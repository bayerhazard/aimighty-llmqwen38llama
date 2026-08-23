# llama-server (ikawrakow/ik_llama.cpp) for Olares One
# Core Ultra 9 275HX (AVX-512, AMX) + RTX 5090 (sm_120 Blackwell)
# Builds main at pinned commit, pushes to ghcr.io/bayerhazard/ik-llama-cpp:<shortsha>

# ---- Stage 1: Build ----
FROM nvidia/cuda:13.1.1-devel-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake ninja-build git ca-certificates pkg-config \
    libcurl4-openssl-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

ARG PIN=8337e4cd3861406fc04e0854b1409cd1b027fbc9

WORKDIR /build
COPY docker/ckpt-fix.patch /build/ckpt-fix.patch
RUN git clone https://github.com/ikawrakow/ik_llama.cpp.git && \
    cd ik_llama.cpp && git checkout ${PIN} && \
    git apply /build/ckpt-fix.patch && \
    git rev-parse HEAD

WORKDIR /build/ik_llama.cpp
RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_CUDA=ON \
    -DGGML_CUDA_FA=ON \
    -DCMAKE_CUDA_ARCHITECTURES=120 \
    -DGGML_IQK_FA_ALL_QUANTS=ON \
    -DGGML_AVX=ON \
    -DGGML_AVX2=ON \
    -DGGML_FMA=ON \
    -DGGML_F16C=ON \
    -DLLAMA_OPENSSL=ON \
    -DLLAMA_CURL=OFF \
    -DCMAKE_EXE_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" \
    -DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/cuda/lib64/stubs -lcuda" \
    && cmake --build build --config Release -j$(nproc) --target llama-server \
    && mkdir -p build/bin \
    && find build -name '*.so*' -print0 | xargs -0 -I{} cp -a {} build/bin/

# ---- Stage 2: Runtime (mirrors buun layout) ----
FROM nvidia/cuda:13.1.1-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 ca-certificates curl bash \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/ik_llama.cpp/build/bin/llama-server /app/llama-server
COPY --from=builder /build/ik_llama.cpp/build/bin/*.so* /app/

ENV LD_LIBRARY_PATH=/app
ENTRYPOINT ["/app/llama-server"]
