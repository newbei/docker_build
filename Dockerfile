# 基础镜像
FROM alibaba-cloud-linux-3-registry.cn-hangzhou.cr.aliyuncs.com/alinux3/python

# 设置工作目录（可选，建议添加，方便后续操作）
WORKDIR /app

# 复制依赖文件到容器中
COPY requirments.txt .

# 安装依赖（使用--no-cache-dir减少镜像体积）
RUN pip install --no-cache-dir -r requirements.txt