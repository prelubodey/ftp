#!/bin/sh

# 1. Сброс переменных
MY_USER="alpineftp"
MY_PASS=""
MY_IP=""

echo "------------------------------------------------------"
echo "--- НАСТРОЙКА FTP СЕРВЕРА (v3.0 Final) ---"
printf "Введите пароль для доступа: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

if [ -z "$MY_IP" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка: IP и пароль не могут быть пустыми!"
    exit 1
fi

echo "🚀 Установка..."

# 2. Очистка старого
docker rm -f camera-ftp 2>/dev/null

# 3. Подготовка папки и ПРАВИЛЬНОГО пароля
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 4. Запуск Docker
# Мы используем трюк: меняем пароль ПЕРЕД запуском или сразу ПРИ старте
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  delfer/alpine-ftp-server

# 5. КРИТИЧЕСКИЙ ШАГ: Жесткая прошивка пароля в систему контейнера
echo "🔐 Фиксация пароля..."
sleep 5
# Эта команда меняет пароль внутри работающего контейнера
docker exec camera-ftp sh -c "echo -e '$MY_PASS\n$MY_PASS' | passwd $MY_USER"
# А эта команда сохраняет состояние контейнера, чтобы изменения не пропали
docker commit camera-ftp camera-ftp-saved

# 6. Перезапуск из сохраненного образа (теперь пароль внутри образа навсегда)
docker rm -f camera-ftp
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  camera-ftp-saved

# 7. Firewall UCI
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
echo "✅ ВСЁ! Теперь пароль сохранится даже после REBOOT."
echo "Хост: $MY_IP | Логин: $MY_USER"
echo "------------------------------------------------------"
exit 0
