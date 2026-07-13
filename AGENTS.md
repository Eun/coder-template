# AGENTS.md

Guidance for AI coding agents working with this Coder workspace template.

## graphify

This template can install the `graphifyy` CLI inside the workspace (optional
workspace parameter `install_graphify`, which runs `pipx install graphifyy`).
The `graphify` skill/CLI builds a knowledge graph of a codebase and lets you
query it.

When running graphify (e.g. the `/graphify` skill) against code that lives in
this Coder workspace, remember the skill's steps assume **local** `bash` /
`python3` execution. In this project, all execution must happen inside the
Coder workspace. So:

- Run EVERY graphify bash/python step inside the Coder workspace (`coder ssh` /
  the Coder workspace bash tool), NEVER the local shell. The source code and the
  `graphify` binary only exist inside the workspace.
- Treat the skill's `INPUT_PATH` as the workspace repo path, e.g.
  `/home/coder/<workspace-name>`.
- `graphify-out/` is created inside the workspace. Read it back with the Coder
  workspace file tools, not local file reads.

### Interpreter note (pipx install)

`install_graphify` installs graphifyy with `pipx`, which places it in an
isolated virtualenv. Consequences the skill must respect:

- The `graphify` binary is on PATH (`~/.local/bin/graphify`) after install.
- `python3 -c "import graphify"` from the SYSTEM interpreter FAILS
  (`ModuleNotFoundError`) — graphify is not importable from system python.
- The skill's Step 1 detection handles this: it reads the `graphify` binary's
  shebang to find the pipx venv interpreter
  (`~/.local/share/pipx/venvs/graphifyy/bin/python`) and uses THAT for all
  `import graphify` / module calls. Do not replace the detected interpreter
  with a bare `python3`.

If you want `import graphify` to work from a plain interpreter instead, install
with `uv tool install graphifyy` or `pip install graphifyy` into a known
environment rather than pipx.
