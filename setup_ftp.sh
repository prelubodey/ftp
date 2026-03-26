#!/bin/sh

# Берем логин и пароль из аргументов команды
MY_USER=$1
MY_PASS=$2

echo "--- СИСТЕМНАЯ НАСТРОЙКА FTP (v11.0 NATIVE) ---"

if [ -z "$MY_USER" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка! Используй запуск с параметрами:"
    echo "sh setup_ftp.sh логин пароль"
    exit 1
fi

# 1. Полная зачистка мусора от прошлых неудачных попыток
echo "🧹 Очистка старых записей..."
sed -i '/для OpenWrt/d' /etc/passwd 2>/dev/null
sed -i '/для OpenWrt/d' /etc/group 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/passwd 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/group 2>/dev/null

# 2. Установка
echo "📦 Установка vsftpd..."
opkg update && opkg install vsftpd

# 3. Создание пользователя вручную
echo "👤 Настройка пользователя: $MY_USER"
echo "$MY_USER:x:1000:1000:$MY_USER:/mnt/userdata/camera:/bin/sh" >> /etc/passwd
echo "$MY_USER:x:1000:$MY_USER" >> /etc/group
printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"

# 4. Проверка шелла
grep -q "/bin/sh" /etc/shells || echo "/bin/sh" >> /etc/shells

# 5. Папка и права
mkdir -p /mnt/userdata/camera
chmod -R 777 /mnt/userdata/camera
chown -R "$MY_USER":root /mnt/userdata/camera

# 6. Конфигурация (с фоновым режимом)
echo "⚙️ Запись конфига..."
cat <<EOF > /etc/vsftpd.conf
listen=YES
background=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
check_shell=NO
local_root=/mnt/userdata/camera
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=30000
pasv_max_port=30009
EOF

# 7. Запуск
echo "🚀 Перезапуск сервиса..."
/etc/init.d/vsftpd enable
/etc/init.d/vsftpd restart

echo "------------------------------------------------------"
echo "✅ ГОТОВО! FTP доступен: $MY_USER / $MY_PASS"
echo "------------------------------------------------------"
