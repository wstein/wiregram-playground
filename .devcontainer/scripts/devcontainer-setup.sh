#!/usr/bin/env bash
set -euo pipefail

# Devcontainer setup script (idempotent)
# Installs asdf, Ruby, Crystal, JRuby, bun, bundler, gh, pandoc, jq, ripgrep, fd

SCRIPTS_DIR="/tmp/devcontainer-scripts"
export ASDF_DIR="$HOME/.asdf"

info() { echo "[devcontainer] $*"; }
warn() { echo "[devcontainer][WARN] $*"; }

# 1) Install system packages that might still be missing
info "Installing/ensuring CLI packages..."
if command -v sudo >/dev/null 2>&1; then
  sudo dnf -y install jq ripgrep fd-find fish pandoc gh || true
else
  dnf -y install jq ripgrep fd-find fish pandoc gh || true
fi

# 2) Install asdf version manager (if not present)
if [ ! -d "$ASDF_DIR" ]; then
  info "Installing asdf..."
  git clone https://github.com/asdf-vm/asdf.git "$ASDF_DIR" --branch v0.13.1
else
  info "asdf already installed"
fi

# Ensure asdf is in current shell
. "$ASDF_DIR/asdf.sh"

# 3) Add plugins and install requested language versions
install_with_asdf_plugin() {
  local plugin="$1"; shift
  local url="$1"; shift || true
  local ver="$1"; shift || true

  if ! asdf plugin-list | grep -q "^${plugin}$"; then
    if [ -n "$url" ]; then
      asdf plugin-add "$plugin" "$url"
    else
      asdf plugin-add "$plugin"
    fi
  else
    info "asdf plugin $plugin already present"
  fi

  if [ -n "$ver" ]; then
    if ! asdf list "$plugin" | grep -q "$ver"; then
      info "Installing $plugin $ver"
      asdf install "$plugin" "$ver"
    else
      info "$plugin $ver already installed"
    fi
    asdf global "$plugin" "$ver"
  fi
}

# Ruby 3.4.x
install_with_asdf_plugin ruby https://github.com/asdf-vm/asdf-ruby.git 3.4.0 || true
# Crystal 1.19.1 (plugin provided by asdf-community)
install_with_asdf_plugin crystal https://github.com/asdf-community/asdf-crystal.git 1.19.1 || true
# JRuby latest stable — use latest listed
if ! asdf plugin-list | grep -q "^jruby$"; then
  asdf plugin-add jruby https://github.com/asdf-community/asdf-jruby.git || true
fi
# Get the latest JRuby version name and install it (best-effort)
if asdf list-all jruby >/dev/null 2>&1; then
  JRUBY_LATEST=$(asdf list-all jruby | tail -n 1 | tr -d '\r')
  if [ -n "$JRUBY_LATEST" ]; then
    install_with_asdf_plugin jruby "" "$JRUBY_LATEST" || true
  fi
fi

# 4) Ensure bundler is present for Ruby
if command -v gem >/dev/null 2>&1; then
  gem install bundler --no-document || true
fi

# 5) Install bun (modern JS runtime/manager) — official install script
if [ ! -d "$HOME/.bun" ]; then
  info "Installing bun (official installer)"
  curl -fsSL https://bun.sh/install | bash || warn "bun install may have failed"
  # ensure bun in PATH for current session
  export PATH="$HOME/.bun/bin:$PATH"
else
  info "bun already installed"
fi

# 6) Check for deprecated / replaced tools and provide replacements
# Example: silver searcher 'ag' often superseded by ripgrep 'rg'
if command -v ag >/dev/null 2>&1; then
  warn "The Silver Searcher (ag) is installed but deprecated in favor of ripgrep (rg). Consider removing ag and using rg."
fi

# 7) VS Code extension replacement checks (idempotent)
# If old Ruby extension exists, ensure Solargraph recommended
if command -v code >/dev/null 2>&1; then
  info "Ensuring recommended VS Code extensions are installed"
  # Replace deprecated Ruby extension if present
  if code --list-extensions | grep -q "rebornix.ruby"; then
    warn "'rebornix.ruby' is deprecated; replacing with 'castwide.solargraph'"
    code --uninstall-extension rebornix.ruby || true
    code --install-extension castwide.solargraph || true
  else
    code --install-extension castwide.solargraph || true
  fi
  code --install-extension crystal-lang.crystal || true
  code --install-extension GitHub.vscode-pull-request-github || true
  code --install-extension ms-azuretools.vscode-docker || true
  code --install-extension tadashi.fish || true
else
  info "VS Code CLI 'code' not available in container; skip extension install."
fi

# 8) Basic checks and outputs
info "Versions summary (best-effort):"
info "ruby: $(ruby -v 2>/dev/null || echo 'ruby not in PATH yet')"
info "crystal: $(crystal -v 2>/dev/null || echo 'crystal not in PATH yet')"
info "jruby: $(jruby -v 2>/dev/null || echo 'jruby not in PATH yet')"
info "bun: $(bun -v 2>/dev/null || echo 'bun not in PATH yet')"
info "pandoc: $(pandoc --version 2>/dev/null | head -n1 || echo 'pandoc not in PATH')"
info "gh: $(gh --version 2>/dev/null | head -n1 || echo 'gh not installed')"

info "Devcontainer setup completed. Please re-open the folder in the container to load shell integrations."
