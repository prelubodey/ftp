#!/bin/sh

# 1. Настройки (измени здесь, если хочешь другой логин/пароль)
MY_USER="anton"
MY_PASS="твой_пароль" 

echo "--- СИСТЕМНАЯ НАСТРОЙКА FTP (v10.0 NATIVE) ---"

# 2. Установка пакета
echo "📦 Установка vsftpd..."
opkg update && opkg install vsftpd

# 3. Создание пользователя вручную
echo "👤 Настройка пользователя $MY_USER..."
# Удаляем старую запись, если она была с ошибкой
sed -i "/$MY_USER/d" /etc/passwd
sed -i "/$MY_USER/d" /etc/group

# Добавляем чистого пользователя
echo "$MY_USER:x:1000:1000:$MY_USER:/mnt/userdata/camera:/bin/sh" >> /etc/passwd
echo "$MY_USER:x:1000:$MY_USER" >> /etc/group

# Установка пароля одной командой (без интерактивности)
printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"

# 4. Добавление шелла
grep -q "/bin/sh" /etc/shells || echo "/bin/sh" >> /etc/shells

# 5. Создание папки и прав
mkdir -p /mnt/userdata/camera
chmod -R 777 /mnt/userdata/camera
chown -R "$MY_USER":root /mnt/userdata/camera

# 6. Запись конфигурации
echo "⚙️ Настройка конфига..."
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

# 7. Запуск сервиса
echo "🚀 Запуск сервера..."
/etc/init.d/vsftpd enable
/etc/init.d/vsftpd restart

echo "------------------------------------------------------"
echo "✅ ГОТОВО! FTP: $MY_USER / $MY_PASS"
echo "------------------------------------------------------"
