#!/bin/bash
# Start script for Voice-Changer on macOS (Apple Silicon)
# Activates conda environment and starts the server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="vcclient"
PORT="${PORT:-18888}"

echo "=== Voice-Changer macOS Server ==="
echo ""

# If conda was just installed by setup-mac.sh, `conda init` has not taken
# effect in this shell yet - source it directly so this still works in the
# same terminal the setup ran in.
if ! command -v conda &> /dev/null && [ -f "$HOME/miniconda3/bin/activate" ]; then
    source "$HOME/miniconda3/bin/activate"
fi

# Initialize conda for bash
eval "$(conda shell.bash hook)"

# Check if environment exists
if ! conda env list | grep -q "^${ENV_NAME} "; then
    echo "Error: Conda environment '${ENV_NAME}' not found."
    echo "Please run setup-mac.sh first:"
    echo "  ./setup-mac.sh"
    exit 1
fi

echo "Activating conda environment '${ENV_NAME}'..."
conda activate ${ENV_NAME}

# Show MPS status
echo ""
echo "Device status:"
python -c "import torch; print(f'  CUDA devices: {torch.cuda.device_count()}')"
python -c "import torch; print(f'  MPS available: {torch.backends.mps.is_available()}')"
echo ""

# Enable MPS fallback to CPU for unsupported operations
# Some PyTorch ops (like weight_norm) aren't implemented for MPS yet
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Create model directory if it doesn't exist
mkdir -p "${SCRIPT_DIR}/model_dir"
mkdir -p "${SCRIPT_DIR}/pretrain"

echo "Starting server on port ${PORT}..."
echo "Web UI will be available at: https://localhost:${PORT}"
echo "(Accept the self-signed certificate warning in your browser)"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

# Start the server
# Pretrained models will be auto-downloaded on first run
cd "${SCRIPT_DIR}"
python MMVCServerSIO.py \
    -p ${PORT} \
    --https true \
    --model_dir model_dir \
    --content_vec_500 pretrain/checkpoint_best_legacy_500.pt \
    --content_vec_500_onnx pretrain/content_vec_500.onnx \
    --content_vec_500_onnx_on true \
    --hubert_base pretrain/hubert_base.pt \
    --hubert_base_jp pretrain/rinna_hubert_base_jp.pt \
    --hubert_soft pretrain/hubert/hubert-soft-0d54a1f4.pt \
    --nsf_hifigan pretrain/nsf_hifigan/model \
    --crepe_onnx_full pretrain/crepe_onnx_full.onnx \
    --crepe_onnx_tiny pretrain/crepe_onnx_tiny.onnx \
    --rmvpe pretrain/rmvpe.pt \
    --rmvpe_onnx pretrain/rmvpe.onnx \
    "$@"
