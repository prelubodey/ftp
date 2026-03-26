#!/bin/sh

# Очистка системных переменных перед стартом
unset MY_USER MY_PASS MY_IP

echo "--- РУЧНАЯ НАСТРОЙКА FTP ---"

# Используем стандартный read без лишних украшательств для стабильности
echo "1. Введите логин:"
read MY_USER
echo "2. Введите пароль:"
read MY_PASS
echo "3. Введите ваш внешний IP (белый IP):"
read MY_IP

echo "------------------------------------------------------"
echo "🚀 Установка для IP: $MY_IP"
echo "------------------------------------------------------"

# Удаление старого контейнера
docker rm -f camera-ftp 2>/dev/null

# Создание папки
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# Запуск Docker (кавычки защищают от ошибок формата)
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "MIN_PORT=30000" \
  -e "MAX_PORT=30009" \
  delfer/alpine-ftp-server

# Настройка внутри
echo "🔐 Финализация настроек..."
sleep 5
docker exec camera-ftp sh -c "echo -e '$MY_PASS\n$MY_PASS' | passwd alpineftp && sed -i 's/alpineftp/$MY_USER/g' /etc/passwd" 2>/dev/null

# Настройка Firewall
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
echo "✅ ГОТОВО! Пробуйте зайти в FileZilla"
echo "Хост: $MY_IP | Логин: $MY_USER"
echo "------------------------------------------------------"#!/bin/sh

# 1. Запрос данных у пользователя
echo "--- НАСТРОЙКА FTP СЕРВЕРА ---"
printf "Введите желаемый логин: "
read MY_USER
printf "Введите желаемый пароль: "
read MY_PASS
printf "Введите ваш внешний IP (белый IP): "
read MY_IP

# Проверка на пустой ввод IP
if [ -z "$MY_IP" ]; then
    echo "❌ Ошибка: IP адрес не может быть пустым!"
    exit 1
fi

echo "------------------------------------------------------"
echo "🚀 Начинаем установку для IP: $MY_IP"
echo "------------------------------------------------------"

# 2. Удаление старого контейнера
docker rm -f camera-ftp 2>/dev/null

# 3. Подготовка папки на роутере
mkdir -p /mnt/userdata/camera && chmod -R 777 /mnt/userdata/camera

# 4. Запуск Docker-контейнера
# Используем кавычки для всех переменных, чтобы избежать ошибок формата
docker run -d \
  --name camera-ftp \
  --restart always \
  --network host \
  -v "/mnt/userdata/camera:/ftp/$MY_USER" \
  -e "ADDRESS=$MY_IP" \
  -e "MIN_PORT=30000" \
  -e "MAX_PORT=30009" \
  delfer/alpine-ftp-server

# 5. Настройка пользователя внутри контейнера
echo "🔐 Настройка учетных данных внутри контейнера..."
sleep 5
# Меняем пароль стандартному пользователю и переименовываем его в системных файлах
docker exec camera-ftp sh -c "echo -e '$MY_PASS\n$MY_PASS' | passwd alpineftp && sed -i 's/alpineftp/$MY_USER/g' /etc/passwd" 2>/dev/null

# 6. Настройка Firewall (UCI)
echo "🛡 Настройка Firewall..."
# Удаляем старое правило, если оно есть
uci delete firewall.@rule[$(uci show firewall | grep 'Allow-FTP-All' | cut -d'[' -f2 | cut -d']' -f1)] 2>/dev/null
# Добавляем новое правило
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
echo "Адрес (Хост): $MY_IP"
echo "Логин: $MY_USER"
echo "Пароль: (тот, что вы ввели)"
echo "------------------------------------------------------"#!/bin/sh

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
