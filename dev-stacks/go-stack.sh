#!/bin/bash
# ============================================================================
# Go Development Stack Installer
# ============================================================================
# Installs: Go, common tools (gopls, delve, golangci-lint), protobuf
# Target: Full Go development environment
# ============================================================================

set -e

# Source common functions (includes aria2 setup)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_header() {
    echo -e "${MAGENTA}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              Go Development Stack Installer                  ║"
    echo "║         Go + Tools + LSP + Linters + Protobuf                ║"
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

log_error() {
    echo -e "${RED}✗${NC} $1"
}

check_arch() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script requires Arch Linux (pacman not found)"
        exit 1
    fi
}

# ============================================================================
# Go Installation
# ============================================================================

install_go() {
    log_step "Installing Go..."

    sudo pacman -S --needed --noconfirm go

    # Setup Go environment
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"

    mkdir -p "$GOPATH"/{bin,src,pkg}

    log_success "Go installed: $(go version)"
}

# ============================================================================
# Essential Go Tools
# ============================================================================

install_go_tools() {
    log_step "Installing Go development tools..."

    # Ensure GOPATH is set
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"

    # Language Server (gopls)
    log_step "Installing gopls (Go language server)..."
    go install golang.org/x/tools/gopls@latest
    log_success "gopls installed"

    # Debugger (delve)
    log_step "Installing delve (debugger)..."
    go install github.com/go-delve/delve/cmd/dlv@latest
    log_success "delve installed"

    # Linter (golangci-lint)
    log_step "Installing golangci-lint..."
    download_pipe "https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh" | sh -s -- -b "$GOBIN" latest
    log_success "golangci-lint installed"

    # Static analysis
    log_step "Installing staticcheck..."
    go install honnef.co/go/tools/cmd/staticcheck@latest
    log_success "staticcheck installed"

    # Code formatting
    log_step "Installing gofumpt (stricter gofmt)..."
    go install mvdan.cc/gofumpt@latest
    log_success "gofumpt installed"

    # Import management
    log_step "Installing goimports..."
    go install golang.org/x/tools/cmd/goimports@latest
    log_success "goimports installed"

    # Test coverage visualization
    log_step "Installing go-cover-treemap..."
    go install github.com/nikolaydubina/go-cover-treemap@latest 2>/dev/null || true

    # Mock generation
    log_step "Installing mockgen..."
    go install go.uber.org/mock/mockgen@latest
    log_success "mockgen installed"

    # Wire (dependency injection)
    log_step "Installing wire..."
    go install github.com/google/wire/cmd/wire@latest
    log_success "wire installed"

    # Air (live reload for development)
    log_step "Installing air (live reload)..."
    go install github.com/air-verse/air@latest
    log_success "air installed"

    # Task runner (like make but better)
    log_step "Installing task..."
    go install github.com/go-task/task/v3/cmd/task@latest
    log_success "task installed"
}

# ============================================================================
# Protocol Buffers
# ============================================================================

install_protobuf() {
    log_step "Installing Protocol Buffers..."

    # Install protoc
    sudo pacman -S --needed --noconfirm protobuf

    # Install Go protobuf plugins
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"

    go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

    log_success "Protocol Buffers installed"
}

# ============================================================================
# Additional System Tools
# ============================================================================

install_system_tools() {
    log_step "Installing supporting system tools..."

    sudo pacman -S --needed --noconfirm \
        git \
        make \
        gcc \
        pkg-config

    log_success "System tools installed"
}

# ============================================================================
# Environment Configuration
# ============================================================================

setup_environment() {
    log_step "Configuring environment variables..."

    local shell_rc=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    # Check if already configured
    if grep -q "GOPATH" "$shell_rc" 2>/dev/null; then
        log_success "Environment already configured in $shell_rc"
        return
    fi

    cat >> "$shell_rc" << 'EOF'

# Go Development Environment
export GOPATH="$HOME/go"
export GOBIN="$GOPATH/bin"
export GOROOT="/usr/lib/go"
export PATH="$GOBIN:$PATH"

# Go module proxy (faster downloads)
export GOPROXY="https://proxy.golang.org,direct"

# Enable Go modules
export GO111MODULE="on"
EOF

    log_success "Environment variables added to $shell_rc"
    log_warning "Run 'source $shell_rc' or start a new terminal to apply changes"
}

# ============================================================================
# Project Template
# ============================================================================

create_project_helper() {
    local helper_script="$HOME/.local/bin/new-go-project"

    mkdir -p "$HOME/.local/bin"

    cat > "$helper_script" << 'SCRIPT'
#!/bin/bash
# Quick Go project scaffolding

if [ -z "$1" ]; then
    echo "Usage: new-go-project <project-name> [type]"
    echo ""
    echo "Types:"
    echo "  cli      - Command line application (default)"
    echo "  api      - REST API server"
    echo "  lib      - Library package"
    exit 1
fi

PROJECT_NAME="$1"
PROJECT_TYPE="${2:-cli}"
MODULE_PATH="${3:-github.com/$USER/$PROJECT_NAME}"

echo "Creating Go project: $PROJECT_NAME (type: $PROJECT_TYPE)"

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Initialize module
go mod init "$MODULE_PATH"

case "$PROJECT_TYPE" in
    cli)
        mkdir -p cmd/$PROJECT_NAME internal pkg
        cat > cmd/$PROJECT_NAME/main.go << 'GO'
package main

import (
	"fmt"
	"os"
)

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}
}

func run() error {
	fmt.Println("Hello, World!")
	return nil
}
GO
        ;;

    api)
        mkdir -p cmd/server internal/{handlers,models,middleware} pkg
        cat > cmd/server/main.go << 'GO'
package main

import (
	"log"
	"net/http"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	log.Println("Starting server on :8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatal(err)
	}
}
GO
        ;;

    lib)
        cat > "$PROJECT_NAME.go" << GO
// Package $PROJECT_NAME provides ...
package $PROJECT_NAME

// Version of this library
const Version = "0.1.0"
GO
        cat > "${PROJECT_NAME}_test.go" << GO
package $PROJECT_NAME

import "testing"

func TestVersion(t *testing.T) {
	if Version == "" {
		t.Error("Version should not be empty")
	}
}
GO
        ;;
esac

# Create common files
cat > .gitignore << 'GITIGNORE'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
/bin/
/dist/

# Test binary
*.test

# Output of go coverage
*.out
coverage.html

# Dependency directories
vendor/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
GITIGNORE

cat > Makefile << 'MAKEFILE'
.PHONY: build test lint run clean

build:
	go build -o bin/$(notdir $(CURDIR)) ./cmd/...

test:
	go test -v -race -coverprofile=coverage.out ./...

lint:
	golangci-lint run

run:
	go run ./cmd/...

clean:
	rm -rf bin/ coverage.out
MAKEFILE

cat > Taskfile.yml << 'TASKFILE'
version: '3'

tasks:
  build:
    cmds:
      - go build -o bin/{{.PROJECT}} ./cmd/...
    vars:
      PROJECT:
        sh: basename $(pwd)

  test:
    cmds:
      - go test -v -race -coverprofile=coverage.out ./...

  lint:
    cmds:
      - golangci-lint run

  run:
    cmds:
      - go run ./cmd/...

  dev:
    cmds:
      - air

  clean:
    cmds:
      - rm -rf bin/ coverage.out
TASKFILE

echo ""
echo "Project created! Next steps:"
echo "  cd $PROJECT_NAME"
echo "  go mod tidy"
echo "  task run  (or: go run ./cmd/...)"
SCRIPT

    chmod +x "$helper_script"
    log_success "Helper script created: new-go-project"
}

# ============================================================================
# Verification
# ============================================================================

verify_installation() {
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation Verification${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Source environment
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export PATH="$GOBIN:$PATH"

    local all_good=true

    # Check Go
    if command -v go &> /dev/null; then
        printf "  %-16s ${GREEN}✓${NC} %s\n" "go:" "$(go version | awk '{print $3}')"
    else
        printf "  %-16s ${RED}✗${NC} not found\n" "go:"
        all_good=false
    fi

    # Check tools
    for tool in gopls dlv golangci-lint staticcheck gofumpt goimports air task; do
        if command -v "$tool" &> /dev/null; then
            printf "  %-16s ${GREEN}✓${NC} installed\n" "$tool:"
        else
            printf "  %-16s ${YELLOW}⚠${NC} not found\n" "$tool:"
        fi
    done

    # Check protoc
    if command -v protoc &> /dev/null; then
        printf "  %-16s ${GREEN}✓${NC} %s\n" "protoc:" "$(protoc --version)"
    else
        printf "  %-16s ${YELLOW}⚠${NC} not found\n" "protoc:"
    fi

    echo ""
    echo "GOPATH: $GOPATH"
    echo ""

    if $all_good; then
        echo -e "${GREEN}All core components installed successfully!${NC}"
    else
        echo -e "${YELLOW}Some components may need manual attention.${NC}"
    fi
}

# ============================================================================
# Main
# ============================================================================

print_header

# Parse arguments
SKIP_VERIFY=false
SKIP_PROTOBUF=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-protobuf)
            SKIP_PROTOBUF=true
            shift
            ;;
        --skip-verify)
            SKIP_VERIFY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-protobuf  Skip Protocol Buffers installation"
            echo "  --skip-verify    Skip verification step"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

check_arch

echo ""
log_step "Starting Go development stack installation..."
echo ""

install_system_tools
install_go
install_go_tools

if ! $SKIP_PROTOBUF; then
    install_protobuf
fi

setup_environment
create_project_helper

if ! $SKIP_VERIFY; then
    verify_installation
fi

echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Go Development Stack Ready!${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "Quick Start:"
echo "  new-go-project my-app          # Create CLI app"
echo "  new-go-project my-api api      # Create API server"
echo "  new-go-project my-lib lib      # Create library"
echo ""
echo "Development commands:"
echo "  task run                       # Run the project"
echo "  task test                      # Run tests"
echo "  task lint                      # Run linter"
echo "  air                            # Live reload development"
echo ""
echo -e "${YELLOW}Remember to restart your terminal or run:${NC}"
echo "  source ~/.bashrc  (or ~/.zshrc)"
echo ""
