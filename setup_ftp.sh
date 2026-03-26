#!/bin/sh

# Аргументы из командной строки
MY_USER=$1
MY_PASS=$2

echo "--- УЛЬТИМАТИВНАЯ НАСТРОЙКА FTP (v12.0 NATIVE) ---"

if [ -z "$MY_USER" ] || [ -z "$MY_PASS" ]; then
    echo "❌ Ошибка! Используй запуск с параметрами:"
    echo "wget -qO- [URL] | sh -s логин пароль"
    exit 1
fi

# 1. Очистка системы от прошлых неудачных попыток
echo "🧹 Чистка старых записей..."
sed -i '/для OpenWrt/d' /etc/passwd 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/passwd 2>/dev/null
sed -i "/^$MY_USER:/d" /etc/group 2>/dev/null

# 2. Установка пакета
echo "📦 Установка vsftpd..."
opkg update && opkg install vsftpd

# 3. Создание пользователя и пароля
echo "👤 Настройка пользователя: $MY_USER"
echo "$MY_USER:x:1000:1000:$MY_USER:/mnt/userdata/camera:/bin/sh" >> /etc/passwd
echo "$MY_USER:x:1000:$MY_USER" >> /etc/group
printf "$MY_PASS\n$MY_PASS\n" | passwd "$MY_USER"
grep -q "/bin/sh" /etc/shells || echo "/bin/sh" >> /etc/shells

# 4. Настройка папок и прав
mkdir -p /mnt/userdata/camera
chmod -R 777 /mnt/userdata/camera
chown -R "$MY_USER":root /mnt/userdata/camera

# 5. Настройка конфигурации (Passive Mode + Background)
echo "⚙️ Запись конфигурации..."
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

# 6. Настройка Firewall (Открываем порты 21 и 30000-30009)
echo "🛡 Настройка Firewall..."
# Удаляем старое правило, если оно было, чтобы не дублировать
uci delete firewall.@rule[$(uci show firewall | grep 'Allow-FTP-Passive' | cut -d'[' -f2 | cut -d']' -f1)] 2>/dev/null
# Добавляем новое
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-FTP-Passive'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].dest_port='21 30000-30009'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart

# 7. Автозапуск и старт
echo "🚀 Запуск сервиса..."
/etc/init.d/vsftpd enable
/etc/init.d/vsftpd restart

echo "------------------------------------------------------"
echo "✅ ВСЁ ГОТОВО И АВТОМАТИЗИРОВАНО!"
echo "Логин: $MY_USER"
echo "Пароль: $MY_PASS"
echo "Порты: 21, 30000-30009 открыты"
echo "------------------------------------------------------"

echo "------------------------------------------------------"
echo "✅ ГОТОВО! FTP: $MY_USER / $MY_PASS"
echo "------------------------------------------------------"
