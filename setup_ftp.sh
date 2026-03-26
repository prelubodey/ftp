#!/bin/sh

# 1. Сброс переменных для чистого запуска
MY_USER="alpineftp"
MY_PASS=""
MY_IP=""

echo "------------------------------------------------------"
echo "--- НАСТРОЙКА FTP СЕРВЕРА (v2.1) ---"
echo "Логин по умолчанию: $MY_USER"
printf "Введите пароль для доступа: "
read MY_PASS
printf "Введите ваш внешний IP: "
read MY_IP

# Проверка на пустой ввод IP
if [ -z "$MY_IP" ]; then
    echo "❌ Ошибка: IP адрес не может быть пустым!"
    exit 1
fi

echo "------------------------------------------------------"
echo "🚀 Начинаем установку для IP: $MY_IP"
echo "------------------------------------------------------"

# 2. Удаление старого контейнера (если он есть)
docker rm -f camera-ftp 2>/dev/null

# 3. Подготовка папки на роутере
# Права 777 нужны, чтобы камера могла записывать без ошибок
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 4. Запуск Docker-контейнера
# Используем network host для прямой работы с портами роутера
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "MIN_PORT=30000" \
  -e "MAX_PORT=30009" \
  delfer/alpine-ftp-server

# 5. Настройка пароля внутри контейнера
echo "🔐 Финализация настроек безопасности..."
sleep 5
# Меняем пароль пользователю alpineftp через стандартный ввод
docker exec camera-ftp sh -c "echo -e '$MY_PASS\n$MY_PASS' | passwd $MY_USER"

# 6. Настройка Firewall FriendlyWrt (UCI)
echo "🛡 Открытие портов в Firewall..."
# Удаляем старое правило с таким именем, если оно затесалось
uci delete firewall.@rule[$(uci show firewall | grep 'Allow-FTP-All' | cut -d'[' -f2 | cut -d']' -f1)] 2>/dev/null

# Добавляем чистое правило для порта 21 и диапазона пассивных портов
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-FTP-All'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='21 30000-30009'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

echo "------------------------------------------------------"
echo "✅ УСТАНОВКА ЗАВЕРШЕНА УСПЕШНО!"
echo "Данные для FileZilla / Камеры:"
echo "Хост (IP): $MY_IP"
echo "Логин: $MY_USER"
echo "Пароль: (тот, что вы ввели)"
echo "------------------------------------------------------"

# Принудительный выход, чтобы избежать зацикливания
exit 0
