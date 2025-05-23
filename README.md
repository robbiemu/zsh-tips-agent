# 💡 zsh-tips-agent

A Zsh tool that provides useful command-line tips based on your actual usage history, leveraging local language models via ollama without slowing down your terminal.

## 🔧 Features

- Suggests underused CLI tools from directories such as `/usr/local/bin` or `brew` packages
- Generates personalized tips based on your command history (`~/.zsh_history`)
- Uses local language models (e.g., via `ollama`) to intelligently generate tips
- Updates tip cache in the background to ensure quick terminal startup
- Automatically refreshes tips periodically

## 🚀 Quickstart

```bash
git clone https://github.com/YOURUSER/zsh-tips-agent.git $GH/zsh-tips-agent
cd $GH/zsh-tips-agent
uv pip install .
zsh-tips-agent install
zsh-tips-agent init --apply
source ~/.zshrc
```

Alternatively, directly add this to your `~/.zshrc`:

```bash
eval "$(zsh-tips-agent init --print)"
```

## ✅ Prerequisites

- [`ollama`](https://ollama.com/) installed and configured locally
- At least one local language model available (`ollama ls`, e.g., `llama3`, `phi3`)
- Python dependencies installed via `uv pip install .`
- CLI tools available on your system (typically `/usr/local/bin`, `brew`)

## 🧠 Tip Generation

Tips are generated using local language models. They are cached and updated periodically in the background, ensuring a responsive terminal.

## ⚙️ Customization

Customize the model and parameters by editing:

```bash
~/.local/share/zsh-tips-agent/config.json
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

If absent, defaults from `agent/config.json` are used. Environment variables can temporarily override these settings:

```bash
ZSH_TIP_MODEL=phi3 python agent/generate_tip.py ...
```

## 📜 License

[LGPLv3](LICENSE)