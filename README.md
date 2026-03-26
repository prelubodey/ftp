# FTP Server for Camera (ARM64 / NanoPi)

Скрипт для быстрой развертки FTP-сервера на роутерах с FriendlyWrt (NanoPi R2S/R4S/R5S) и других ARM64 устройствах через Docker.

## 🚀 Особенности
- **Безопасность:** Не хранит IP, логины и пароли в коде (запрашивает при запуске).
- **Автоматизация:** Сам определяет внешний IP и настраивает Firewall (UCI).
- **Совместимость:** Работает на базе `delfer/alpine-ftp-server` (идеально для ARM64).

## 🛠 Установка одной командой
Запустите этот код в терминале вашего роутера:

```bash
wget -qO- [https://raw.githubusercontent.com/prelubodey/ftp/main/setup_ftp.sh](https://raw.githubusercontent.com/prelubodey/ftp/main/setup_ftp.sh) | sh
