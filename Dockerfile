# 思源笔记 MCP Server Dockerfile
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 安装 uv
RUN pip install uv

# 复制依赖文件
COPY pyproject.toml uv.lock ./

# 安装依赖
RUN uv sync --frozen --no-dev

# 复制源代码
COPY src/ ./src/

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 暴露端口
EXPOSE 8000

# 默认运行方式
CMD ["python", "-m", "siyuan_mcp_server", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8000"]
