# 💡 zsh-tips-agent

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
echo 'source $GH/zsh-tips-agent/.zshrc_snippet' >> ~/.zshrc
````

Make sure:

* You have `smolagent`, `ollama`, and your desired models installed locally.
* Your tools are discoverable in `/usr/local/bin` or via `brew`.

## 🧠 Tip Generation

Tips are generated in the background using a local LLM. You can customize this process via `agent/generate_tip.py`.

---

> Tip generation doesn't block terminal load: the previous tip is cached and displayed immediately.
