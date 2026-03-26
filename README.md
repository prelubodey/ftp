# Auto-Setup FTP Server for FriendlyWrt (NanoPi)

Скрипт для быстрой установки и настройки нативного FTP-сервера (`vsftpd`) на роутерах с прошивкой FriendlyWrt/OpenWrt. 

### 🌟 Особенности
* **Без Docker:** Работает напрямую в системе, потребляет минимум RAM.
* **Надежность:** Пароль сохраняется в системе и не сбрасывается после перезагрузки.
* **Автоматизация:** Сам создает пользователя, настраивает права и открывает порты.
* **Passive Mode:** Настроен диапазон портов `30000-30009` для работы за NAT.

---

### 🚀 Быстрая установка (одной командой)

Зайдите в терминал роутера (через SSH или Web-консоль) и вставьте:

```bash
wget -qO- [https://raw.githubusercontent.com/prelubodey/ftp/main/setup_ftp.sh](https://raw.githubusercontent.com/prelubodey/ftp/main/setup_ftp.sh) | sh
```
Как изменить пароль (существующему юзеру)
```bash
passwd имя
```
