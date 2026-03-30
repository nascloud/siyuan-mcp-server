# Siyuan MCP Server - Agent 开发指南

本文件为 Agent 提供开发规范和代码上下文。

## 项目概述

- **类型**: Python MCP (Model Context Protocol) Server
- **目标**: 为思源笔记提供 MCP 工具接口
- **Python 版本**: >= 3.10
- **包管理**: uv
- **MCP SDK**: FastMCP (fastmcp)

## 构建与测试命令

### 安装依赖
```bash
uv sync
```

### 开发运行
```bash
uv run siyuan_mcp_server
uv run python -c "import siyuan_mcp_server; print('ok')"
```

### 编译检查
```bash
uv run python -m compileall src
```

### 测试
```bash
uv run python -m unittest discover
```

### 环境变量
- `SIYUAN_API_TOKEN`: 思源笔记 API Token（必填）
- `SIYUAN_API_URL`: 思源服务器地址，默认 `http://127.0.0.1:6806`

## 代码结构

```
src/siyuan_mcp_server/
├── __init__.py      # 主入口，定义所有 MCP tools
└── tools.py         # 工具函数（敏感信息打码等）
```

## 代码风格规范

### 命名约定
- **函数**: snake_case (`find_notebooks`, `get_block_content`)
- **内部函数**: 前缀 `_` (`_post_to_siyuan_api`, `_push_message`)
- **常量**: UPPER_SYNTAX (`_ACTION_LABELS`, `_STAGE_LABELS`)
- **类型注解**: 使用 typing 模块 (`Dict`, `List`, `Optional`, `Tuple`)

### 导入顺序
```python
# 标准库
import base64
import difflib
import json
import os
import re
from typing import Any, Dict, List, Optional, Tuple

# 第三方库
import requests
from fastmcp import FastMCP

# 本地模块
from .tools import is_siyuan_timestamp, mask_sensitive_data
```

### MCP Tool 定义
```python
@mcp.tool()
def tool_name(param: str, optional_param: Optional[str] = None) -> Dict[str, Any]:
    """工具描述（中文）。
    
    适用场景:
        - 场景1说明
        - 场景2说明
    
    使用方法:
        - param: 参数说明
        - optional_param: 可选参数说明
    
    注意事项:
        - 重要提示1
        - 重要提示2
    
    Args:
        param: 参数说明
        optional_param: 可选参数说明
    
    Returns:
        返回值说明
    """
    # 实现...
```

### 内部函数约定
- 内部辅助函数使用 `_` 前缀
- 返回类型必须标注
- 必须包含 docstring

## 核心原则：禁止静默执行

**所有非只读操作必须推送通知！**

### 写操作通知规范
```python
# 成功时
_push_message("操作名", "语义化描述")

# 失败时
_push_error_message("操作名", "错误描述")
raise
```

### 禁止行为
- ❌ 静默执行写操作
- ❌ 仅记录日志不推送通知
- ❌ 假设用户知道发生了什么

### 通知文案要求
- 用户可读：说明"操作了什么 + 结果如何"
- 避免技术参数（内部ID、字节长度等）
- 格式：`标题：内容`

### 统一入口函数
- `_push_message(title, msg)` - 成功通知
- `_push_error_message(title, msg)` - 失败通知
- `_humanize_error(e)` - 异常转语义化消息
- `_shorten(text, max_len)` - 文本截断

## 错误处理模式

### 标准写操作流程
```python
try:
    # 1. 参数校验
    if not param.strip():
        raise ValueError("param must be non-empty")
    
    # 2. 执行操作
    result = _post_to_siyuan_api("/api/endpoint", payload)
    
    # 3. 发送成功通知
    _push_message("操作名", "成功描述")
    return result
except Exception as e:
    # 4. 发送错误通知并抛出
    _push_error_message("操作名", _humanize_error(e))
    raise
```

### 异常类型映射
- `ValueError` → "输入内容不符合要求"
- `ConnectionError` → "暂时无法连接思源"
- `TypeError` → "返回数据格式异常"

## 安全规范

### SQL 查询
- 仅允许 `SELECT` 语句
- 使用参数化查询或 `_sql_escape()` 转义

### 敏感数据打码
- 所有返回内容必须经过 `mask_sensitive_data()`
- kramdown 使用 `parse_and_mask_kramdown()`

### 历史文件访问
- 路径必须以 `/history` 或 `/data/history` 开头
- 文档删除不暴露 MCP 接口

## 块操作语义

### insert_block 优先级
`nextID > previousID > parentID`

### move_block 规则
- 标题块：按"分节范围"移动
- 其他块：按"子树块组"移动
- 禁止仅移动父块本身

### 参数验证
- 块 ID 格式：`\d{14}-[a-zA-Z0-9]+`
- 时间戳格式：`\d{14}` (YYYYMMDDHHMMSS)
- `data_type` 仅允许 `markdown` 或 `dom`

## 开发流程

### 变更验证步骤
1. 运行 `lsp_diagnostics` 检查语法
2. 运行 `python -m compileall src` 编译检查
3. 运行 `python -c "import siyuan_mcp_server"` 导入检查
4. 运行 `python -m unittest discover` 测试

### 文档同步
- 修改 tool 行为必须更新 docstring
- 涉及 move_block 必须更新 README.md

## 常用代码片段

### 调用思源 API
```python
result = _post_to_siyuan_api("/api/endpoint", {"key": "value"})
```

### 获取思源服务器地址
```python
base_url = _get_siyuan_base_url()  # 返回基础 URL，支持自定义配置
```

### 块操作辅助
```python
# 获取块元数据
meta = _get_block_metadata(block_id)

# 获取块内容预览
preview = _get_block_content_preview(block_id, max_len=30)

# 获取子块
children = _get_child_blocks_rows(parent_id)
```

### 类型检查
```python
if not isinstance(result, dict):
    raise TypeError(f"Expected dict, got {type(result)}")
```
