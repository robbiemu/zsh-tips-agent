# 💡 zsh-tips-agent

A Zsh tool that provides useful command-line tips based on your actual usage history, leveraging local language models via ollama without slowing down your terminal.

## 🔧 Features

- Suggests underused CLI tools from directories such as `/usr/local/bin` or `brew` packages
- Generates personalized tips based on your command history (`~/.zsh_history`)
- Uses local language models (e.g., via `ollama`) to intelligently generate tips
- Updates tip cache in the background to ensure quick terminal startup
- Tips are cached and updated in the background (default: `~/.local/share/zsh-tips-agent/data/`)
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

Tips são geradas usando modelos de linguagem locais. Elas são armazenadas em cache e atualizadas periodicamente em segundo plano, garantindo um terminal responsivo. Os arquivos de cache ficam em `~/.local/share/zsh-tips-agent/data/`.

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

Here’s an updated section for your **README.md** that clearly explains custom installations and how the agent’s environment variables ensure everything works out of the box, even for non-standard install locations.

### 🛠️ Custom Installation & Non-Standard Prefixes

You can install **zsh-tips-agent** to a custom directory by specifying a `--prefix`:

```bash
zsh-tips-agent install --prefix /opt/zsh-tips-agent
zsh-tips-agent init --prefix /opt/zsh-tips-agent --apply
source ~/.zshrc
```

This ensures all scripts and data will use `/opt/zsh-tips-agent` as the base instead of `/usr/local`.

* The initialization step (`init`) will insert a block into your `.zshrc` that references your custom install path.
* When updating the tip cache, the agent now passes the correct path (`PROJECT_DIR`) automatically—**you do not need to set any extra environment variables yourself.**
* All scripts, cache, and background updates will work with your chosen prefix transparently.

If you ever need to move or reinstall to a different location, simply rerun the `init` step with your new prefix to update `.zshrc`.

### Example for a Home Directory Install

```bash
zsh-tips-agent install --prefix $HOME/.local/zsh-tips-agent
zsh-tips-agent init --prefix $HOME/.local/zsh-tips-agent --apply
source ~/.zshrc
```

---

### ⚠️ Notes

* The `.zshrc` snippet manages all necessary environment variables for you.
* Manual edits or environment exports (like `PROJECT_DIR`) are **not needed**.
* All agent scripts and cache updates are path-aware based on your chosen prefix.

## 📜 License

[LGPLv3](LICENSE)