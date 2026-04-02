FROM slimerl/slime:latest

LABEL maintainer="Zhangzh"
LABEL version="2026.3.11.post1"
LABEL description="Update sglang router align to official version"

ENV PIP_BREAK_SYSTEM_PACKAGES=1

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai

ARG PATCH_VERSION=latest
# 该megatron分支是slime官方验证的兼容版本
ARG MEGATRON_COMMIT=3714d81d418c9f1bca4594fc35f9e8289f652862
ARG SLIME_COMMIT=main
ARG ENABLE_CUDA_13=0

# 原始构建在/root下，与aladdin workshop冲突，workshop的root会覆盖镜像中/root的内容，需要迁移

## 1. 卸载原来在 /root 下 editable 安装的包
RUN pip uninstall -y megatron-core slime 2>/dev/null || true
RUN rm -rf /root/Megatron-LM /root/slime

## 2. 设置新 WORKDIR
WORKDIR /build_workspace

#  重新安装 Megatron-LM 
RUN git clone https://github.com/NVIDIA/Megatron-LM.git --recursive && \
    cd Megatron-LM && git checkout ${MEGATRON_COMMIT} && \
    pip install -e .

# 重新 Apply Megatron Patch 
COPY docker/slime/patch/${PATCH_VERSION}/megatron.patch /build_workspace/Megatron-LM/
RUN cd /build_workspace/Megatron-LM && \
    git update-index --refresh && \
    git apply megatron.patch --3way && \
    if grep -R -n '^<<<<<<< ' .; then \
      echo "Patch failed to apply cleanly. Please resolve conflicts." && \
      exit 1; \
    fi && \
    rm megatron.patch

RUN git clone https://github.com/THUDM/slime.git /build_workspace/slime && \
    cd /build_workspace/slime && \
    git checkout ${SLIME_COMMIT} && \
    cd /build_workspace/slime/slime/backends/megatron_utils/kernels/int4_qat && \
    pip install . --no-build-isolation


RUN apt-get update && \
    apt-get install -y openssh-server net-tools vim telnet iputils-ping unzip bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 兼容aladdin连接端口
EXPOSE 8080
