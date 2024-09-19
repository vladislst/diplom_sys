# Дипломная работа по профессии «Системный администратор» - Степанов Владислав
  
Задание:[Дипломная работа](https://github.com/netology-code/sys-diplom/tree/diplom-zabbix?tab=readme-ov-file#%D0%B7%D0%B0%D0%B4%D0%B0%D1%87%D0%B)
  
## Инфраструктура

### Terraform

Для развёртки инфраструктуры были использованы Terraform и Ansible.\
*Описание инфраструктуры находится в файле terraform/main.tf\
\
Был создан каталог далее разворачивание происходило при помощи terraform.\
![cloud](./img/cloud.jpg)
\
Созданные ВМ
\
![VM](./img/VM.jpg)

Используемая конфигурации VM:2 ядра 20% Intel ice lake, 2-4Гб памяти, 10hdd, прерываемая.\

### Ansible

Инвентарь хостов из FQDN\
\
![invent](invent.jpg)
\
Проверка доступности\
\
![ping](ansible_ping.jpg)

## Сайт

Созданы две ВМ в разных зонах, с установленым на них сервером nginx и был настроен балансировщик\

### Настройка веб-серверов nginx на ВМ

![ansible_nginx](./img/ansible_nginx.jpg)

Плейбук:[nginx.yml](./ansible/nginx.yml)

### Страничка сайта

![alt text](web_alb.jpg)

### Настройка балансировщика

#### Создан Target Group

![target_group](./img/target_group.jpg)

#### Создан Backend Group

![backend_group](./img/backend_group.jpg)
![backend_group](./img/backend_group2.jpg)

#### HTTP router

![http_route](./img/http_route.jpg)

#### Создан Application load balancer

![alb](./img/alb.jpg)

`Тестируем сайт curl -v <публичный IP балансера>:80`

![curl_alb](./img/curl_alb.jpg)

Лог балансировщика

![alb_log](./img/alb_log.jpg)

## Мониторинг

### Zabbix сервер

#### Устанавливаем сервер по средством ansible

![ansible_zabbix_server](./img/ansible_zabbix_server.jpg)

Плейбук:[zabbix_server.yml](./ansible/zabbix_server.yml)

#### Установиваем Zabbix Agent на каждую ВМ и настраиваем агенты на отправление метрик в Zabbix.

![ansible_zabbix_agent](./img/ansible_zabbix_agent.jpg)

Плейбук:[zabbix_agent.yml](./ansible/zabbix_agent.yml)

![zabbix-web](./img/zabbix-web.jpg)

Пример дашборда:

![zabbix-web2](./img/zabbix-web2.jpg)

## Логи

### Разверачиваем Elasticsearch

![ansible_elastic](./img/ansible_elastic.jpg)

Плейбук:[elasticsearch.yml](./ansible/elasticsearch.yml)

### Разверачиваем filebeat на web серверах

![ansible_filebeat](./img/ansible_filebeat.jpg)

Плейбук:[filebeat.yml](./ansible/filebeat.yml)

### Разверачиваем kibana

![ansible_kibana](./img/ansible_kibana.jpg)

Плейбук:[kibana.yml](./ansible/kibana.yml)

#### Kibana

![kibana](./img/elastic.jpg)

## Сеть

### VPC

Развернута VPC.\
Сервера web, Elasticsearch поместите в приватные подсети.\
Сервера Zabbix, Kibana, application load balancer определите в публичную подсеть.\

![map_vpc](./img/map_vpc.jpg)
![net](net.jpg)

## Резервное копирование

snapshot дисков создаются для всех ВМ. Время жизни snaphot неделя. snaphot настроены на ежедневное копирование.

![backup](./img/backup.jpg)