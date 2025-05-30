#!/usr/bin/env python3
"""Smart tip generator for under‑used CLI tools with a single CodeAgent."""

from __future__ import annotations
import json
import os
import shutil
import subprocess
import sys
import textwrap
from pathlib import Path
from typing import Optional
from smolagents import CodeAgent, LiteLLMModel, Tool

# ---------------- Config ----------------


def load_model_cfg() -> tuple[str, dict, int]:
    user_cfg = Path.home() / ".local" / "share" / "zsh-tips-agent" / "config.json"
    if user_cfg.is_file():
        cfg = user_cfg
    else:
        cfg = Path(__file__).parent / "config.json"
    model_id = os.getenv("ZSH_TIP_MODEL", "gemma3")
    params: dict = {}
    tokens = 4096
    if cfg.exists():
        c = json.loads(cfg.read_text())
        model_id = c.get("model_id", model_id)
        params = c.get("model_params", {})
        tokens = int(params.get("num_ctx", tokens))
    if tokens == 4096:
        try:
            show = subprocess.check_output(["ollama", "show", model_id], text=True)
            for ln in show.splitlines():
                if any(k in ln.lower() for k in ("num_ctx", "context length")):
                    tokens = int(ln.split()[-1])
                    break
        except Exception:
            pass
    return model_id, params, tokens


def truncate(txt: str, limit: int, ratio: float = 3.5) -> str:
    return txt[-int(limit * ratio) :]


def looks_binary(p: str, n: int = 1024) -> bool:
    with open(p, "rb") as f:
        return b"\0" in f.read(n)


# ------------- Tool base helpers -------------

BASE_INPUTS = {"name": {"type": "string", "description": "tool name"}}


class _BaseTool(Tool):
    inputs = BASE_INPUTS
    output_type = "string"


class BrewInfoTool(_BaseTool):
    name = "brew_info"
    description = "Full `brew info` output"

    def forward(self, name: str) -> Optional[str]:
        try:
            return subprocess.check_output(["brew", "info", name], text=True)
        except Exception:
            return None


class ManTool(_BaseTool):
    name = "man_page"
    description = "Rendered man page via `col -bx`"

    def forward(self, name: str) -> Optional[str]:
        try:
            raw = subprocess.check_output(
                ["man", name], text=True, stderr=subprocess.STDOUT
            )
            return subprocess.run(
                ["col", "-bx"], input=raw, text=True, capture_output=True
            ).stdout
        except Exception:
            return None


class InfoTool(_BaseTool):
    name = "info_page"
    description = "GNU info page"

    def forward(self, name: str) -> Optional[str]:
        try:
            return subprocess.check_output(
                ["info", name], text=True, stderr=subprocess.STDOUT
            )
        except Exception:
            return None


class TldrTool(_BaseTool):
    name = "tldr_page"
    description = "Local TLDR examples"

    def forward(self, name: str) -> Optional[str]:
        for cmd in (["tlrc", "--no-color", "--quiet", name], ["tldr", "-q", name]):
            if shutil.which(cmd[0]):
                try:
                    return subprocess.check_output(cmd, text=True)
                except subprocess.CalledProcessError:
                    return None
        return None


class HelpTool(_BaseTool):
    name = "help_flag"
    description = "Output from the `<command> --help` if available."

    def forward(self, name: str) -> Optional[str]:
        try:
            return subprocess.check_output(
                [name, "--help"], text=True, stderr=subprocess.STDOUT
            )
        except Exception:
            return None


class ProbeTool(_BaseTool):
    name = "probe"
    description = "Show the location and type of a command"

    def forward(self, name: str) -> Optional[str]:
        path = shutil.which(name)
        if not path:
            return f"Command '{name}' not found in PATH."
        abs_path = os.path.realpath(path)
        directory = os.path.dirname(abs_path)
        try:
            file_output = subprocess.check_output(
                ["file", "--brief", "--mime", abs_path], text=True
            ).strip()
        except subprocess.CalledProcessError:
            file_output = "Unknown file type"
        is_binary = "charset=binary" in file_output
        return (
            f"Command: {name}\n"
            f"Full Path: {abs_path}\n"
            f"Directory: {directory}\n"
            f"File Type: {file_output}\n"
            f"Is Binary: {'Yes' if is_binary else 'No'}"
        )


class ScriptTool(_BaseTool):
    name = "script_source"
    description = "Inspect the entire command, if is text."

    def forward(self, name: str) -> Optional[str]:
        path = shutil.which(name)
        if not path or looks_binary(path):
            return None
        try:
            return Path(path).read_text(errors="ignore")
        except Exception:
            return None


# ------------- LLM setup -------------

MODEL_ID, MODEL_PARAMS, TOKEN_LIMIT = load_model_cfg()
LLM = LiteLLMModel(model_id=f"ollama/{MODEL_ID}", **MODEL_PARAMS)


class TipAgent(CodeAgent):
    def __init__(self):
        super().__init__(
            model=LLM,
            tools=[
                BrewInfoTool(),
                ManTool(),
                InfoTool(),
                TldrTool(),
                HelpTool(),
                ProbeTool(),
                ScriptTool(),
            ],
        )

    def plan(self, tool_name: str):
        return textwrap.dedent("""Your job is to provide a concise, friendly 1-2 sentence tip about a given CLI command.
            Try to make sure the tips you write won't look repetitive or generic. It should be encouranging and inviting.
            You can use tool calls to collect information before generating the tip. 
            YOU MUST MAKE AT LEAST ONE TOOL call. If you feel confident that you know the command, it is generally still worthwhile to use at least one tool call to verify before generating the tip.
            Try to FIND AT LEAST ONE NATURAL LANGUAGE DESCRIPTION of the command to help you write the tip. 
            DO NOT use the final_answer tool to note progress, use it only after you are done all other tool calling.
            DO NOT guess what a command is without exhausting all resources first.
            Only once you have sufficient information, output ONLY the tip using the `final_answer` tool in a code block, following this format:

            ```py
            final_answer("Your tip here")
            ```<end_code>
        """)

    def run_tip(self, tool: str) -> str:
        return self.run(self.plan(tool), additional_args={"tool": tool})


# ------------- Orchestrator -------------


def generate_tip(tool: str) -> str:
    return TipAgent().run_tip(tool)


def main(tool: str, cache_path: str, tip_path: str):
    tool = tool.strip()
    if not tool:
        print("Error: Tool name is missing or blank.")
        sys.exit(1)

    tip = generate_tip(tool)
    cache_file = Path(cache_path)
    try:
        cache = json.loads(cache_file.read_text()) if cache_file.exists() else {}
    except json.JSONDecodeError:
        cache = {}

    now = int(Path().stat().st_mtime)  # fallback if date fails
    try:
        now = int(subprocess.check_output(["date", "+%s"], text=True).strip())
    except Exception:
        pass

    cache[tool] = {"tip": tip, "last_shown": now}
    cache_file.write_text(json.dumps(cache, indent=2))
    Path(tip_path).write_text(tip + "\n")
    print(tip)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: generate_tip.py <tool> <cache.json> <tipfile>")
        sys.exit(1)
    main(*sys.argv[1:])
