#!/bin/bash

set -e  # Exit on error

echo "🔍 Detecting package manager..."
if command -v apt >/dev/null 2>&1; then
    PKG_MGR="apt"
    PYTHON_VENV_PKG="python3-venv"
    DOCKER_PKG="docker.io"
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
    PYTHON_VENV_PKG="python3-venv"  # Might be in python3 module
    DOCKER_PKG="docker"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
    PYTHON_VENV_PKG="python3-venv"
    DOCKER_PKG="docker"
else
    echo "❌ Unsupported OS: no apt, yum, or dnf found."
    exit 1
fi

echo "✅ Using package manager: $PKG_MGR"

# Install required packages
if [ "$PKG_MGR" = "apt" ]; then
    echo "🔍 Checking if python3-venv is installed..."
    if ! dpkg -s python3-venv >/dev/null 2>&1; then
        echo "⚠️  python3-venv not found. Installing..."
        sudo apt update -y
        sudo apt install -y $DOCKER_PKG $PYTHON_VENV_PKG
    else
        echo "✅ python3-venv is already installed."
    fi
else
    echo "🔍 Installing Python venv and Docker..."
    sudo $PKG_MGR install -y $DOCKER_PKG python3 python3-pip python3-virtualenv || \
    sudo $PKG_MGR install -y $DOCKER_PKG python3 python3-pip python3-venv
fi

# Create virtual environment if missing
VENV_DIR="venv"
ACTIVATE="$VENV_DIR/bin/activate"

if [ ! -f "$ACTIVATE" ]; then
    echo "📦 (Re)creating virtual environment in $VENV_DIR..."
    rm -rf "$VENV_DIR"
    python3 -m venv "$VENV_DIR"
    echo "✅ Virtual environment created."
else
    echo "✅ Virtual environment already exists."
fi

# Activate virtual environment
echo "🐍 Activating virtual environment..."
source "$ACTIVATE"

# Install requirements
if [ -f "requirements.txt" ]; then
    echo "📦 Installing Python packages from requirements.txt..."
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "✅ Python packages installed."
else
    echo "❌ requirements.txt not found!"
    exit 1
fi

# Check Docker installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Fix Docker socket permissions
if [ -S /var/run/docker.sock ]; then
    echo "🛠️  Fixing Docker socket permissions..."
    sudo chmod 777 /var/run/docker.sock
    echo "✅ Docker socket permissions updated."
else
    echo "❌ Docker socket not found!"
    exit 1
fi

# Run Python app
echo "🚀 Running sre-ui.py..."
python3 sre-ui.py

