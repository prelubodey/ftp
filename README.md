# 📸 FTP Server for Camera (NanoPi / FriendlyWrt)

Универсальный скрипт для быстрого развертывания FTP-сервера на роутерах с Docker (NanoPi R2S/R4S/R5S, FriendlyWrt) и других ARM64 устройствах.

## ✨ Особенности
- **Интерактивность:** Скрипт запрашивает логин, пароль и IP при запуске.
- **Безопасность:** В коде на GitHub нет ваших личных данных.
- **Автоматизация:** Сам создает папки, настраивает права (777) и открывает порты в Firewall роутера (UCI).
- **Пассивный режим:** Настроен диапазон портов `30000-30009` для стабильной работы камер через интернет.

## 🚀 Быстрый запуск
Скопируйте и вставьте эту команду в терминал вашего роутера:

```bash
wget -qO setup_ftp.sh "https://raw.githubusercontent.com/prelubodey/ftp/main/setup_ftp.sh" && sh setup_ftp.sh
```
Если вы хотите сменить пароль на уже работающем сервере, выполните:
```bash
docker exec -it camera-ftp passwd alpineftp
```
🛠 Скрипт полной очистки
```bash
echo "🧹 Начинаем полную очистку FTP..."

# 1. Останавливаем и удаляем контейнер
docker stop camera-ftp 2>/dev/null
docker rm -f camera-ftp 2>/dev/null

# 2. Удаляем образ (чтобы он скачался заново)
docker rmi delfer/alpine-ftp-server 2>/dev/null

# 3. Удаляем папку с данными (ВНИМАНИЕ: все записи камер будут удалены!)
rm -rf /mnt/userdata/camera

# 4. Удаляем правила из Firewall (UCI)
RULE_NUM=$(uci show firewall | grep "name='Allow-FTP-All'" | cut -d'[' -f2 | cut -d']' -f1)
if [ -n "$RULE_NUM" ]; then
    echo "🛡 Удаляем правило Firewall №$RULE_NUM..."
    uci delete firewall.@rule[$RULE_NUM]
    uci commit firewall
    /etc/init.d/firewall restart
fi

# 5. Удаляем сам файл скрипта, если он остался
rm -f setup_ftp.sh
echo "------------------------------------------------------"
echo "✨ СИСТЕМА ЧИСТА! Можно ставить заново."
echo "------------------------------------------------------"
```
