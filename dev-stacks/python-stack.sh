#!/bin/bash
# ============================================================================
# Python Development Stack Installer
# ============================================================================
# Installs: Python 3, pip, pipx, poetry, pyenv, common tools
# Target: Full Python development environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║             Python Development Stack Installer               ║"
    echo "║        Python + Poetry + Ruff + Pyright + Tools              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log_step() {
    echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        echo -e "${RED}This script requires Arch Linux${NC}"
        exit 1
    fi
}

install_python() {
    log_step "Installing Python..."

    sudo pacman -S --needed --noconfirm \
        python \
        python-pip \
        python-pipx

    # Ensure pipx path
    pipx ensurepath 2>/dev/null || true

    log_success "Python installed: $(python --version)"
}

install_tools() {
    log_step "Installing Python development tools..."

    # Poetry - dependency management
    log_step "Installing Poetry..."
    pipx install poetry
    log_success "Poetry installed"

    # Ruff - fast linter/formatter
    log_step "Installing Ruff..."
    pipx install ruff
    log_success "Ruff installed"

    # Pyright - type checker
    log_step "Installing Pyright..."
    sudo pacman -S --needed --noconfirm pyright
    log_success "Pyright installed"

    # Black - code formatter (backup to ruff)
    log_step "Installing Black..."
    pipx install black
    log_success "Black installed"

    # pytest
    log_step "Installing pytest..."
    pipx install pytest
    log_success "pytest installed"

    # httpie - better curl
    log_step "Installing HTTPie..."
    pipx install httpie
    log_success "HTTPie installed"

    # ipython - better REPL
    log_step "Installing IPython..."
    sudo pacman -S --needed --noconfirm ipython
    log_success "IPython installed"
}

install_pyenv() {
    log_step "Installing pyenv (Python version manager)..."

    if command -v pyenv &> /dev/null; then
        log_success "pyenv already installed"
        return
    fi

    # Install pyenv dependencies
    sudo pacman -S --needed --noconfirm \
        base-devel openssl zlib xz tk

    # Install pyenv
    download_pipe "https://pyenv.run" | bash

    log_success "pyenv installed"
}

setup_environment() {
    log_step "Configuring environment..."

    local shell_rc=""
    if [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if grep -q "PYENV_ROOT" "$shell_rc" 2>/dev/null; then
        log_success "Environment already configured"
        return
    fi

    cat >> "$shell_rc" << 'EOF'

# Python Development Environment
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)" 2>/dev/null || true

# Poetry
export PATH="$HOME/.local/bin:$PATH"
EOF

    log_success "Environment configured in $shell_rc"
}

create_project_helper() {
    local helper_script="$HOME/.local/bin/new-python-project"

    mkdir -p "$HOME/.local/bin"

    cat > "$helper_script" << 'SCRIPT'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: new-python-project <project-name>"
    exit 1
fi

PROJECT_NAME="$1"

echo "Creating Python project: $PROJECT_NAME"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize with Poetry
poetry init --no-interaction --name "$PROJECT_NAME" --python "^3.11"

# Create project structure
mkdir -p src/$PROJECT_NAME tests

cat > src/$PROJECT_NAME/__init__.py << PY
"""$PROJECT_NAME package."""

__version__ = "0.1.0"
PY

cat > src/$PROJECT_NAME/main.py << 'PY'
"""Main module."""


def main() -> None:
    """Entry point."""
    print("Hello, World!")


if __name__ == "__main__":
    main()
PY

cat > tests/__init__.py << 'PY'
"""Test package."""
PY

cat > tests/test_main.py << 'PY'
"""Test main module."""

from src.main import main


def test_main(capsys) -> None:
    """Test main function."""
    main()
    captured = capsys.readouterr()
    assert "Hello" in captured.out
PY

cat > pyproject.toml << TOML
[tool.poetry]
name = "$PROJECT_NAME"
version = "0.1.0"
description = ""
authors = ["Your Name <you@example.com>"]
readme = "README.md"
packages = [{include = "$PROJECT_NAME", from = "src"}]

[tool.poetry.dependencies]
python = "^3.11"

[tool.poetry.group.dev.dependencies]
pytest = "^8.0"
ruff = "^0.1"
pyright = "^1.1"

[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pyright]
pythonVersion = "3.11"
typeCheckingMode = "basic"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
TOML

cat > .gitignore << 'GITIGNORE'
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.eggs/
.pytest_cache/
.ruff_cache/
.mypy_cache/
.venv/
venv/
.env
GITIGNORE

# Install dependencies
poetry install

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  poetry shell"
echo "  python -m src.$PROJECT_NAME.main"
SCRIPT

    chmod +x "$helper_script"
    log_success "Helper script created: new-python-project"
}

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Verification${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    export PATH="$HOME/.local/bin:$PATH"

    for cmd in python pip poetry ruff black pytest http; do
        if command -v "$cmd" &> /dev/null; then
            printf "  %-12s ${GREEN}✓${NC} %s\n" "$cmd:" "$($cmd --version 2>&1 | head -1)"
        else
            printf "  %-12s ${YELLOW}⚠${NC} not found\n" "$cmd:"
        fi
    done

    echo ""
}

# Main
print_header
check_arch

log_step "Starting Python development stack installation..."
echo ""

install_python
install_tools
install_pyenv
setup_environment
create_project_helper
verify_installation

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Python Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  new-python-project my-app    # Create new project"
echo "  poetry new my-app            # Alternative: Poetry scaffold"
echo ""
echo "Development commands:"
echo "  poetry shell                 # Activate virtual environment"
echo "  ruff check .                 # Lint code"
echo "  ruff format .                # Format code"
echo "  pytest                       # Run tests"
echo ""
