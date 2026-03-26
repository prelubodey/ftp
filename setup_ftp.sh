#!/bin/sh

# 1. Ввод данных
echo "--- НАСТРОЙКА FTP (v6.0 FORCE) ---"
printf "Введите логин: "
read MY_USER
printf "Введите пароль: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

if [ -z "$MY_IP" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка: Заполните все поля!"
    exit 1
fi

# 2. Полная зачистка старого контейнера и его остатков
docker rm -f camera-ftp 2>/dev/null
docker volume rm ftp_data 2>/dev/null

# 3. Подготовка папки
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 4. Запуск контейнера с принудительной перезаписью конфига
echo "🚀 Запуск сервера..."
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

# 5. КЛЮЧЕВОЙ МОМЕНТ: Принудительное обновление базы пользователей внутри
echo "🔐 Прошивка вашего пароля в базу данных сервера..."
sleep 5
# Мы вручную создаем файл со списком пользователей и обновляем базу БД
docker exec camera-ftp sh -c "echo -e '$MY_USER\n$MY_PASS' > /etc/vsftpd/virtual_users.txt && db_load -T -t hash -f /etc/vsftpd/virtual_users.txt /etc/vsftpd/virtual_users.db"

# 6. Firewall
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
echo "✅ ТЕПЕРЬ ПАРОЛЬ ТОЧНО ВАШ!"
echo "Логин: $MY_USER | Пароль: $MY_PASS"
echo "------------------------------------------------------"
exit 0
