# lab1devops

## Завдання
Варіант 8
V2 = 1 MariaDB
V3 = 3 Simple Inventory
V4 = 4 Порт 8000


Simple Inventory — сервіс обліку обладнання, написаний за допомогою Swift та фреймворка Vapor

Об’єкт інвентарю містить наступні поля
id
name
quantity
created_at
API сервісу складається з 3 ендпоінтів
GET /items — вивести список усіх предметів в інвентарі (id,name)
POST /items (name, quantity) — створити новий запис у системі обліку
GET /items/<id> — вивести детальну інформацію по запису в інвентарі (id, name, quantity, created_at)

## Установка

Система - Ubuntu server
[Завантажити](https://ubuntu.com/download/server/arm)

Вимоги:
4gb ram
4cpu 
20-30gb disk

спец налаштування:
необхідно обов'язково відмітити пункт - Install OpenSSH server 

## Підключення 

в терміналі 
```bash
ssh username@ip.address
```

## Налаштування
```bash
git clone https://github.com/Useraccont1507/lab1devops

cd lab1devops

chmod +x setup.sh

sudo ./setup.sh
```

## Тестування

Тестування доступності веб-сервера (Nginx + Vapor + MariaDB):

У браузері хост-машини відкрито адресу http://ip.address

Результат: Успішне завантаження сторінки застосунку без помилки "502 Bad Gateway".

В термінлі хост-машини виконанти будь який запит 

```bash
curl -X GET http://ip.address/items \
-H "Content-Type: application/json"
```

Результат: Успішне завантаження без помилки.

Тестування створення користувачів:

Виконано команди su - student та su - operator із введенням заданого скриптом пароля (1111).

Результат: Успішний вхід, що підтверджує коректне створення ізольованих акаунтів.

Тестування специфічних прав (Sudoers) для користувача operator:

З-під користувача operator виконано команду sudo systemctl restart lab1devops.service.

Результат: Сервіс успішно перезапустився без запиту пароля для sudo, що підтверджує правильність конфігурації у /etc/sudoers.d/operator.

Тестування блокування дефолтного користувача:

Дія: Після виконання скриптом команд usermod -L username та usermod -s /usr/sbin/nologin username, поточну сесію було закрито (exit) та здійснено спробу повторного підключення по SSH (ssh username@ip.address).

Результат: Система відмовила в доступі, повністю заблокувавши дефолтний акаунт, як того вимагало завдання.

