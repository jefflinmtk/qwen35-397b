#!/usr/bin/env bash
# =============================================================================
# 01_download_model.sh
# Download nvidia/Qwen3.5-397B-A17B-NVFP4 to the SHARED NFS path (/srv/hf),
# so all 6 GB10 nodes see it at the same location.
# Uses screen (survives disconnects) + hf_transfer (multi-connection speed).
# =============================================================================
set -euo pipefail

MODEL_REPO="nvidia/Qwen3.5-397B-A17B-NVFP4"
export HF_HOME="${HF_HOME:-/srv/hf}"     # same shared path used by the cluster
SCREEN_NAME="qwen35-dl"

# Optional HF token (public Apache-2.0 model; token only removes anon rate limits)
# export HF_TOKEN=hf_xxxxxxxxxxxxxxxxxxxx

mkdir -p "$HF_HOME"
export HF_HUB_ENABLE_HF_TRANSFER=1

echo ">> Installing HF CLI + accelerated transfer (throwaway venv)"
python3 -m venv /tmp/hfdl_venv
# shellcheck disable=SC1091
source /tmp/hfdl_venv/bin/activate
pip install -q --upgrade pip
pip install -q "huggingface_hub[cli,hf_transfer]"

if [[ -n "${HF_TOKEN:-}" ]]; then
  hf auth login --token "$HF_TOKEN" --add-to-git-credential || true
fi

DL_CMD=$(cat <<EOF
export HF_HOME='$HF_HOME'
export HF_HUB_ENABLE_HF_TRANSFER=1
source /tmp/hfdl_venv/bin/activate
echo '>> Download started at' \$(date)
hf download $MODEL_REPO --repo-type model --max-workers 16
echo '>> Download FINISHED at' \$(date)
echo '>> Cached under: '\$HF_HOME'/hub'
EOF
)

echo ">> Launching download inside screen '$SCREEN_NAME'"
screen -L -Logfile "$HF_HOME/download_${SCREEN_NAME}.log" \
       -dmS "$SCREEN_NAME" bash -lc "$DL_CMD"

echo ">> Started. Watch progress:"
echo "   screen -r $SCREEN_NAME            # attach (detach: Ctrl-a then d)"
echo "   tail -f $HF_HOME/download_${SCREEN_NAME}.log"
echo "   du -sh $HF_HOME/hub"
