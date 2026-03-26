#!/bin/sh

# 1. Сброс переменных
MY_USER="alpineftp"
MY_PASS=""
MY_IP=""

echo "------------------------------------------------------"
echo "--- НАСТРОЙКА FTP СЕРВЕРА (v2.2 Stable) ---"
printf "Введите пароль для доступа: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

if [ -z "$MY_IP" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка: IP и пароль не могут быть пустыми!"
    exit 1
fi

echo "🚀 Установка..."

# 2. Очистка
docker rm -f camera-ftp 2>/dev/null

# 3. Папка
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 4. Запуск Docker (ДОБАВЛЕНА ПЕРЕМЕННАЯ FTP_PASS)
# Теперь пароль привязан к самому контейнеру и не сбросится
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "FTP_USER=$MY_USER" \
  -e "FTP_PASS=$MY_PASS" \
  -e "MIN_PORT=30000" \
  -e "MAX_PORT=30009" \
  delfer/alpine-ftp-server

# 5. Firewall UCI
echo "🛡 Настройка Firewall..."
uci delete firewall.@rule[$(uci show firewall | grep 'Allow-FTP-All' | cut -d'[' -f2 | cut -d']' -f1)] 2>/dev/null
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-FTP-All'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='21 30000-30009'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

echo "------------------------------------------------------"
echo "✅ ГОТОВО! Пароль теперь зафиксирован."
echo "Хост: $MY_IP | Логин: $MY_USER"
echo "------------------------------------------------------"
exit 0
