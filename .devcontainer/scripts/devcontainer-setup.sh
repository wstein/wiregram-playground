#!/usr/bin/env bash
set -euo pipefail

# Devcontainer setup script (idempotent)

SCRIPTS_DIR="/tmp/devcontainer-scripts"
export ASDF_DIR="$HOME/.asdf"

info() { echo "[devcontainer] $*"; }
warn() { echo "[devcontainer][WARN] $*"; }

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
#install_with_asdf_plugin ruby https://github.com/asdf-vm/asdf-ruby.git 3.4.0 || true
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
# if command -v gem >/dev/null 2>&1; then
#   gem install bundler --no-document || true
# fi

# 5) Install bun (modern JS runtime/manager) — official install script
if [ ! -d "$HOME/.bun" ]; then
  info "Installing bun (official installer)"
  curl -fsSL https://bun.sh/install | bash || warn "bun install may have failed"
  # ensure bun in PATH for current session
  export PATH="$HOME/.bun/bin:$PATH"
else
  info "bun already installed"
fi

# 7) Configure Starship prompt for fish (if installed)
if command -v starship >/dev/null 2>&1; then
  info "Configuring Starship for fish"
  mkdir -p "$HOME/.config/fish"
  # Add initialization line if not present
  if ! grep -q 'starship init fish' "$HOME/.config/fish/config.fish" 2>/dev/null; then
    echo 'status --is-interactive; and starship init fish | source' >> "$HOME/.config/fish/config.fish"
  else
    info "Starship already configured in fish"
  fi
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
