#!/bin/sh

# --- НАСТРОЙКИ (Данные запрашиваются при запуске) ---
echo "Введите имя пользователя FTP (например, camera):"
read MY_USER
echo "Введите пароль для $MY_USER:"
read MY_PASS

# Автоматическое определение внешнего IP роутера
MY_IP=$(curl -s https://ifconfig.me)

echo "------------------------------------------------------"
echo "🚀 Начинаем установку..."
echo "📍 Ваш внешний IP: $MY_IP (определен автоматически)"
echo "------------------------------------------------------"

# 1. Удаление старого контейнера
docker rm -f camera-ftp 2>/dev/null

# 2. Подготовка папки
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 3. Запуск контейнера
# Мы используем переменную $MY_IP, которую скрипт узнал выше
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v /mnt/userdata/camera:/ftp/$MY_USER \
  -e ADDRESS=$MY_IP \
  -e MIN_PORT=30000 \
  -e MAX_PORT=30009 \
  delfer/alpine-ftp-server

# 4. Принудительная настройка пользователя и пароля внутри Docker
echo "🔐 Настройка учетных данных..."
sleep 3
# Переименовываем стандартного пользователя и ставим ему пароль
docker exec camera-ftp sh -c "sed -i 's/alpineftp/$MY_USER/g' /etc/passwd && echo -e '$MY_PASS\n$MY_PASS' | passwd $MY_USER"

# 5. Настройка Firewall (UCI)
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
echo "✅ УСТАНОВКА ЗАВЕРШЕНА!"
echo "Логин: $MY_USER"
echo "Пароль: (скрыт)"
echo "IP для камеры: $MY_IP"
echo "------------------------------------------------------"
