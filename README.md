Sites-Metrics-Stats
============================

Приложение для получения информации о метриках, используемых в топ-50 сайтах России(по версии SimilarWeb).
Определяет, использует ли сайт Я. Метрику, GoogleAnalytics или же иной сервис метрики.

* Использует фреймворк Mojolicious
* Данные о сайтах обновляются по расписанию(каждую минуту) при помощи плагина Cron для Mojolicious
* Конфигурация соединения с БД может быть инициализирована через config/config.ini, либо через переменные среды
* Журнал с ошибками в ходе работы приложения — log/errors.log(конфигурация в файле log.conf)

Страница с информацией о сайтах доступна по адресу https://$HOSTNAME/top_sites.

В БД используется таблица ***sites*** со следующими колонками:

* **id** — primary key
* **name** — имя сайта
* **metrics** — сервисы метрики
* **comment** — ошибка, по которой не удалось в последний раз обновить данные по сайту
* **position** — позиция сайта в топе
