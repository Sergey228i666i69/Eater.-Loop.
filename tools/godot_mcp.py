#!/usr/bin/env python3
"""Small CLI wrapper for the local Godot Native MCP server."""

from __future__ import annotations

import argparse
import json
import sys
import urllib.error
import urllib.request
from typing import Any


DEFAULT_URL = "http://127.0.0.1:9080/mcp"


class McpError(RuntimeError):
    pass


def _json_arg(value: str) -> Any:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value


def _post(url: str, payload: dict[str, Any], timeout: float) -> dict[str, Any]:
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Accept": "application/json, text/event-stream",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError as exc:
        raise McpError(f"Cannot reach Godot MCP at {url}: {exc}") from exc


def _rpc(url: str, method: str, params: dict[str, Any] | None, timeout: float) -> Any:
    payload = {"jsonrpc": "2.0", "id": 1, "method": method}
    if params is not None:
        payload["params"] = params
    response = _post(url, payload, timeout)
    if "error" in response:
        raise McpError(json.dumps(response["error"], ensure_ascii=False, indent=2))
    return response.get("result")


def _tool_text(result: dict[str, Any]) -> Any:
    if "structuredContent" in result:
        return result["structuredContent"]
    content = result.get("content", [])
    if len(content) == 1 and content[0].get("type") == "text":
        text = content[0].get("text", "")
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text
    return result


def call_tool(url: str, tool_name: str, arguments: dict[str, Any], timeout: float) -> Any:
    result = _rpc(
        url,
        "tools/call",
        {"name": tool_name, "arguments": arguments},
        timeout,
    )
    if result.get("isError"):
        raise McpError(json.dumps(result, ensure_ascii=False, indent=2))
    return _tool_text(result)


def read_resource(url: str, uri: str, timeout: float) -> Any:
    result = _rpc(url, "resources/read", {"uri": uri}, timeout)
    contents = result.get("contents", [])
    if len(contents) == 1:
        text = contents[0].get("text", "")
        try:
            return json.loads(text)
        except json.JSONDecodeError:
            return text
    return result


def print_json(value: Any, compact: bool) -> None:
    if isinstance(value, str):
        print(value)
        return
    indent = None if compact else 2
    print(json.dumps(value, ensure_ascii=False, indent=indent, sort_keys=not compact))


def parse_key_values(items: list[str]) -> dict[str, Any]:
    arguments: dict[str, Any] = {}
    for item in items:
        if "=" not in item:
            raise McpError(f"Argument must be key=value: {item}")
        key, value = item.split("=", 1)
        arguments[key] = _json_arg(value)
    return arguments


def main() -> int:
    raw_args = sys.argv[1:]
    compact = "--compact" in raw_args
    raw_args = [arg for arg in raw_args if arg != "--compact"]

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--compact", action="store_true", default=compact)
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("init", help="Show MCP server capabilities")
    subparsers.add_parser("tools", help="List available MCP tools")
    subparsers.add_parser("resources", help="List available MCP resources")
    subparsers.add_parser("info", help="Shortcut for get_project_info")
    subparsers.add_parser("scene", help="Shortcut for get_current_scene")
    subparsers.add_parser("state", help="Shortcut for get_editor_state")

    logs_parser = subparsers.add_parser("logs", help="Shortcut for get_editor_logs")
    logs_parser.add_argument("--source", default="editor_panel")
    logs_parser.add_argument("--count", type=int, default=50)
    logs_parser.add_argument("--order", choices=["asc", "desc"], default="desc")

    call_parser = subparsers.add_parser("call", help="Call a named MCP tool")
    call_parser.add_argument("tool")
    call_parser.add_argument("arguments", nargs="*", help="Tool arguments as key=value")
    call_parser.add_argument("--json", help="Complete tool arguments as JSON object")

    resource_parser = subparsers.add_parser("resource", help="Read an MCP resource URI")
    resource_parser.add_argument("uri")

    args = parser.parse_args(raw_args)

    try:
        if args.command == "init":
            result = _rpc(
                args.url,
                "initialize",
                {
                    "protocolVersion": "2025-03-26",
                    "capabilities": {},
                    "clientInfo": {"name": "godot-mcp-cli", "version": "1.0"},
                },
                args.timeout,
            )
        elif args.command == "tools":
            result = _rpc(args.url, "tools/list", {}, args.timeout)
        elif args.command == "resources":
            result = _rpc(args.url, "resources/list", {}, args.timeout)
        elif args.command == "info":
            result = call_tool(args.url, "get_project_info", {}, args.timeout)
        elif args.command == "scene":
            result = call_tool(args.url, "get_current_scene", {}, args.timeout)
        elif args.command == "state":
            result = call_tool(args.url, "get_editor_state", {}, args.timeout)
        elif args.command == "logs":
            result = call_tool(
                args.url,
                "get_editor_logs",
                {"source": args.source, "count": args.count, "order": args.order},
                args.timeout,
            )
        elif args.command == "call":
            if args.json:
                result_args = json.loads(args.json)
            else:
                result_args = parse_key_values(args.arguments)
            result = call_tool(args.url, args.tool, result_args, args.timeout)
        elif args.command == "resource":
            result = read_resource(args.url, args.uri, args.timeout)
        else:
            parser.error(f"Unknown command: {args.command}")
        print_json(result, args.compact)
        return 0
    except (McpError, json.JSONDecodeError) as exc:
        print(f"godot_mcp.py: error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
