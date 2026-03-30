# 思源笔记 MCP Server Dockerfile
FROM python:3.12-slim

# 设置工作目录
WORKDIR /app

# 复制源代码
COPY src/ ./src/

# 复制依赖文件
COPY pyproject.toml README.md ./

# 安装依赖（直接安装到系统 Python）
RUN pip install --no-cache-dir -e .

# 创建非 root 用户
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# 暴露端口
EXPOSE 8000

# 默认运行方式
CMD ["python", "-m", "siyuan_mcp_server", "--transport", "streamable-http", "--host", "0.0.0.0", "--port", "8000"]
