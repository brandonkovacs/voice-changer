#!/bin/bash
# Setup script for Voice-Changer on macOS (Apple Silicon)
# Creates conda environment with Python 3.10 and installs dependencies

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="vcclient"
export CONDA_PLUGINS_AUTO_ACCEPT_TOS=yes

echo "=== Voice-Changer macOS Setup ==="
echo ""

# Check if conda is available. Not being on PATH does not mean it is not
# installed - reuse an existing install rather than failing on the installer's
# "prefix already exists" error.
if ! command -v conda &> /dev/null; then
    if [ -f "$HOME/miniconda3/bin/activate" ]; then
        echo "Found existing Miniconda at $HOME/miniconda3, activating..."
        source "$HOME/miniconda3/bin/activate"
    else
        echo "conda not found. Installing Miniconda..."
        curl -fL -O https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh
        bash ./Miniconda3-latest-MacOSX-arm64.sh -b -p "$HOME/miniconda3"
        source ~/miniconda3/bin/activate
        conda init --all
        rm Miniconda3-latest-MacOSX-arm64.sh
    fi
fi

# Initialize conda for bash
eval "$(conda shell.bash hook)"

# Check if environment already exists
if conda env list | grep -q "^${ENV_NAME} "; then
    echo "Conda environment '${ENV_NAME}' already exists."
    read -p "Do you want to recreate it? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing environment..."
        conda env remove -n ${ENV_NAME} -y
    else
        echo "Using existing environment."
        conda activate ${ENV_NAME}
        echo ""
        echo "To start the server, run: ./start-mac.sh"
        exit 0
    fi
fi

echo ""
echo "Creating conda environment '${ENV_NAME}' with Python 3.10..."
conda create -n ${ENV_NAME} python=3.10 -y

echo ""
echo "Activating environment..."
conda activate ${ENV_NAME}

echo ""
echo "Installing PyTorch with MPS (Metal) support..."
pip install torch==2.0.1 torchaudio==2.0.2

echo ""
echo "Installing remaining dependencies..."
pip install -r "${SCRIPT_DIR}/requirements-mac.txt"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "MPS (Metal) availability:"
python -c "import torch; print(f'  MPS available: {torch.backends.mps.is_available()}')"
python -c "import torch; print(f'  MPS built: {torch.backends.mps.is_built()}')"
echo ""
echo "To start the server:"
echo "  cd ${SCRIPT_DIR}"
echo "  ./start-mac.sh"
echo ""
echo "Or manually:"
echo "  conda activate ${ENV_NAME}"
echo "  python MMVCServerSIO.py -p 18888 --https true"
