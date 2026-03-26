#!/bin/sh

# 1. Сброс и ввод данных
MY_USER="alpineftp"
echo "------------------------------------------------------"
echo "--- НАСТРОЙКА FTP СЕРВЕРА (v4.0 Ultra-Stable) ---"
printf "Введите пароль для доступа: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

if [ -z "$MY_IP" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка: Данные не введены!"
    exit 1
fi

# 2. Генерируем MD5-хэш пароля (это то, что понимает Alpine внутри Docker)
# Мы используем openssl, который обычно есть в FriendlyWrt
MY_HASH=$(printf "$MY_PASS" | openssl passwd -1 -stdin)

echo "🚀 Установка..."

# 3. Очистка старого хлама
docker rm -f camera-ftp 2>/dev/null
docker rmi camera-ftp-saved 2>/dev/null

# 4. Создаем папку
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 5. Запуск Docker (ПРАВИЛЬНЫЙ МЕТОД)
# Мы передаем готовый хэш в переменную FTP_PASS
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "FTP_USER=$MY_USER" \
  -e "FTP_PASS=$MY_HASH" \
  delfer/alpine-ftp-server

# 6. Настройка Firewall (UCI)
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
echo "✅ ГОТОВО! Теперь пароль вшит намертво."
echo "Хост: $MY_IP | Логин: $MY_USER"
echo "------------------------------------------------------"
exit 0
