#!/bin/sh

# 1. Ввод данных
echo "--- НАСТРОЙКА FTP СЕРВЕРА (v5.0 vsftpd) ---"
printf "Введите желаемый логин: "
read MY_USER
printf "Введите желаемый пароль: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

if [ -z "$MY_IP" ] || [ -z "$MY_PASS" ] || [ -z "$MY_USER" ]; then
    echo "❌ Ошибка: Все поля должны быть заполнены!"
    exit 1
fi

echo "🚀 Удаление старых версий..."
docker rm -f camera-ftp 2>/dev/null

# 2. Подготовка папки
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 3. Запуск нового образа (fauria/vsftpd)
# Он идеально работает с внешним IP и пассивными портами
echo "🚀 Запуск нового контейнера..."
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/home/vsftpd/$MY_USER" \
  -e "FTP_USER=$MY_USER" \
  -e "FTP_PASS=$MY_PASS" \
  -e "PASV_ADDRESS=$MY_IP" \
  -e "PASV_MIN_PORT=30000" \
  -e "PASV_MAX_PORT=30009" \
  fauria/vsftpd

# 4. Настройка Firewall (UCI)
echo "🛡 Открытие портов в Firewall..."
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
echo "✅ ВСЁ ГОТОВО! Пробуйте зайти в FileZilla."
echo "Хост: $MY_IP"
echo "Логин: $MY_USER"
echo "Пароль: (ваш пароль)"
echo "------------------------------------------------------"
exit 0
