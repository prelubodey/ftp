#!/bin/sh

# 1. Ввод данных
echo "--- СИСТЕМНАЯ НАСТРОЙКА FTP (v9.0 NATIVE) ---"
printf "Введите логин: "
read MY_USER
printf "Введите пароль: "
read MY_PASS

if [ -z "$MY_USER" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка: Логин и пароль не могут быть пустыми!"
    exit 1
fi

# 2. Установка пакета
echo "📦 Установка vsftpd..."
opkg update && opkg install vsftpd

# 3. Создание пользователя вручную (для OpenWrt/FriendlyWrt)
echo "👤 Создание пользователя $MY_USER..."
if ! grep -q "^$MY_USER:" /etc/passwd; then
    echo "$MY_USER:x:1000:1000:$MY_USER:/mnt/userdata/camera:/bin/sh" >> /etc/passwd
    echo "$MY_USER:x:1000:$MY_USER" >> /etc/group
    echo "Пользователь создан. Установите пароль:"
    printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"
else
    echo "Пользователь уже существует, обновляем пароль..."
    printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"
fi

# 4. Добавление шелла (чтобы не было ошибки 530)
if ! grep -q "/bin/sh" /etc/shells; then
    echo "/bin/sh" >> /etc/shells
fi

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
echo "✅ ВСЁ ГОТОВО! FTP работает напрямую в системе."
echo "Логин: $MY_USER"
echo "Папка: /mnt/userdata/camera"
echo "------------------------------------------------------"
