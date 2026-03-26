#!/bin/sh

# Аргументы из командной строки
MY_USER=$1
MY_PASS=$2

echo "--- СИСТЕМНАЯ НАСТРОЙКА FTP (v11.0 NATIVE) ---"

# Проверка, что аргументы переданы
if [ -z "$MY_USER" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка! Нужно запускать так:"
    echo "wget -qO- [URL] | sh -s логин пароль"
    exit 1
fi

# 1. Вычищаем мусор от прошлых попыток
sed -i '/для OpenWrt/d' /etc/passwd 2>/dev/null
sed -i '/для OpenWrt/d' /etc/group 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/passwd 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/group 2>/dev/null

# 2. Установка
opkg update && opkg install vsftpd

# 3. Создание пользователя вручную
echo "$MY_USER:x:1000:1000:$MY_USER:/mnt/userdata/camera:/bin/sh" >> /etc/passwd
echo "$MY_USER:x:1000:$MY_USER" >> /etc/group
printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"

# 4. Настройка конфига
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

# 5. Права и запуск
grep -q "/bin/sh" /etc/shells || echo "/bin/sh" >> /etc/shells
mkdir -p /mnt/userdata/camera
chmod -R 777 /mnt/userdata/camera
chown -R "$MY_USER":root /mnt/userdata/camera

/etc/init.d/vsftpd enable
/etc/init.d/vsftpd restart

echo "------------------------------------------------------"
echo "✅ ГОТОВО! FTP: $MY_USER / $MY_PASS"
echo "------------------------------------------------------"
