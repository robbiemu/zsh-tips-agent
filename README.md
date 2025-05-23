# 💡 zsh-tips-agent
<small>_v.0.1.1_</small>

A background-aware Zsh enhancement that shows helpful, low-use custom tooltips each time you open a terminal — powered by your actual usage history and LLM-generated suggestions.

## 🔧 Features

- Highlights underused CLI tools from `/usr/local/bin` and `brew` packages
- Reads usage frequency from your `~/.zsh_history`
- Generates tip text using local LLMs via [SmolAgents](https://github.com/smol-ai/smol-agent)
- Runs tip generation in the background to avoid blocking terminal startup
- Tips are cached and rotated daily (or however often you prefer)

## 🗂️ Project Layout

```

zsh-tips-agent/
├── bin/
│   └── update\_tip\_cache.sh      # Scans tools, usage, triggers tip generation
├── agent/
│   └── generate\_tip.py          # SmolAgent that generates a tip with Ollama
├── data/
│   └── tip\_cache.json           # Cached tips by tool
├── .zshrc\_snippet               # Add to your \~/.zshrc

````

## 🚀 Getting Started

```bash
git clone https://github.com/YOURUSER/zsh-tips-agent.git $GH/zsh-tips-agent
cd $GH/zsh-tips-agent
uv pip install .
zsh-tips-agent init --apply
source ~/.zshrc
````

*Optional:* Use the one-liner version instead:

```bash
eval "$(zsh-tips-agent init)"
```

### ✅ Requirements

* [`ollama`](https://ollama.com/) installed and running locally
* Local models available via `ollama ls` (e.g. `llama3`, `phi3`)
* `smolagents` Python package (installed automatically by `uv pip install .`)
* Custom tools installed in `/usr/local/bin` or via `brew`

The system will show a cached tip on each terminal startup and update the tip quietly in the background.

## 🧠 Tip Generation

Tips are generated in the background using a local LLM. You can customize this process via `agent/generate_tip.py`.

---

> Tip generation doesn't block terminal load: the previous tip is cached and displayed immediately.

## ⚙️ Configuration

You can customize which model is used for tip generation (and how it's configured) by editing the local `config.json` file:

```bash
$GH/zsh-tips-agent/agent/config.json
```

Example:

```json
{
  "model_id": "llama3",
  "model_params": {
    "temperature": 0.7,
    "top_p": 0.9
  }
}
```

* `model_id` should match a model available via `ollama ls`
* `model_params` accepts any valid generation settings supported by your model

You can also override these temporarily using environment variables:

```bash
ZSH_TIP_MODEL=phi3 python agent/generate_tip.py ...
```

---

> ⚠️ The config is optional — if not present, the system defaults to `llama3` with no parameters.
