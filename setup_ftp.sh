#!/bin/sh

# 1. Запрос данных (используем printf для надежности)
echo "--- НАСТРОЙКА FTP ---"
printf "Введите имя пользователя: "
read MY_USER
printf "Введите пароль: "
read MY_PASS

# 2. Надежное определение IP (пробуем два разных сервиса)
MY_IP=$(curl -s https://api.ipify.org || curl -s https://ident.me)

# Проверка, что IP получен, а не ошибка 403
if echo "$MY_IP" | grep -q "html"; then
    MY_IP="46.148.186.180" # Ваш текущий IP как запасной вариант
fi

echo "------------------------------------------------------"
echo "🚀 Начинаем установку для IP: $MY_IP"
echo "------------------------------------------------------"

# 3. Полная очистка
docker rm -f camera-ftp 2>/dev/null

# 4. Подготовка папки
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 5. Запуск Docker (переменные в кавычках обязательны!)
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "MIN_PORT=30000" \
  -e "MAX_PORT=30009" \
  delfer/alpine-ftp-server

# 6. Смена пароля внутри
echo "🔐 Финализация настроек..."
sleep 5
docker exec camera-ftp sh -c "echo -e '$MY_PASS\n$MY_PASS' | passwd alpineftp"
# Если логин не alpineftp, пробуем переименовать (для совместимости)
if [ "$MY_USER" != "alpineftp" ]; then
    docker exec camera-ftp sh -c "sed -i 's/alpineftp/$MY_USER/g' /etc/passwd" 2>/dev/null
fi

# 7. Настройка Firewall (UCI)
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
echo "------------------------------------------------------"
