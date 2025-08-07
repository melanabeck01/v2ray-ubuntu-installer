# V2Ray Installer for Ubuntu 22/24

Автоматический установщик V2Ray для Ubuntu Server 22.04/24.04.

## Установка

### Быстрая установка (одной командой)
```bash
curl -sL https://raw.githubusercontent.com/yourusername/v2ray-installer/main/install_v2ray_improved.sh | sudo bash
```

### Ручная установка
```bash
wget https://raw.githubusercontent.com/yourusername/v2ray-installer/main/install_v2ray_improved.sh
chmod +x install_v2ray_improved.sh
sudo ./install_v2ray_improved.sh
```

### Локальная установка
```bash
# На удаленном сервере
scp install_v2ray_improved.sh root@YOUR_SERVER_IP:/tmp/
ssh root@YOUR_SERVER_IP '/tmp/install_v2ray_improved.sh'
```

## Что устанавливается

- V2Ray последней версии
- WebSocket транспорт на порту 8443
- Автозапуск через systemd
- Настройка UFW firewall
- Генерация уникального UUID

## Проверка установки

```bash
# Статус сервиса
systemctl status v2ray

# Проверка порта
netstat -tlnp | grep 8443

# Полная диагностика
./check_install.sh
```

## Конфигурация клиента

После установки скрипт выведет:

1. **JSON конфигурацию для клиентов:**
```json
{
  "v": "2",
  "ps": "V2Ray-SERVER_IP",
  "add": "SERVER_IP",
  "port": "8443",
  "id": "GENERATED_UUID",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "",
  "path": "/ws",
  "tls": ""
}
```

2. **vmess:// ссылку для быстрого импорта:**
```
vmess://BASE64_ENCODED_CONFIG
```

Просто скопируйте vmess:// ссылку и вставьте в ваш V2Ray клиент для автоматического импорта настроек.

## Управление сервисом

```bash
# Запуск
systemctl start v2ray

# Остановка
systemctl stop v2ray

# Перезапуск
systemctl restart v2ray

# Автозапуск
systemctl enable v2ray

# Отключить автозапуск
systemctl disable v2ray
```

## Удаление

```bash
systemctl stop v2ray
systemctl disable v2ray
rm -f /etc/systemd/system/v2ray.service
rm -rf /etc/v2ray
rm -f /usr/local/bin/v2ray
ufw delete allow 8443
systemctl daemon-reload
```

## Файлы

- `/etc/v2ray/config.json` - конфигурация
- `/usr/local/bin/v2ray` - исполняемый файл
- `/etc/systemd/system/v2ray.service` - systemd сервис

## Логи

```bash
# Просмотр логов
journalctl -u v2ray -f

# Последние логи
journalctl -u v2ray --lines=50
```

## Поддерживаемые системы

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS  
- Ubuntu 24.04 LTS

## Порты

- 8443/tcp - V2Ray WebSocket

Убедитесь что порт 8443 открыт в облачной панели управления провайдера.

## Клиенты

Рекомендуемые клиенты:
- Windows: v2rayN
- macOS: V2rayU
- iOS: Shadowrocket, Quantumult X
- Android: v2rayNG

Вставьте JSON конфигурацию в настройки клиента или импортируйте по QR-коду.