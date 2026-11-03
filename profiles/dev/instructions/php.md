# PHP Instructions

Инструкции для PHP-кода в профиле dev.

## Toolchain
- PHP 8.3+, Composer 2, Symfony 7 / Laravel 11
- Статический анализ: PHPStan (level max) или Psalm
- Стиль: PHP-CS-Fixer (PSR-12), Rector для апгрейдов
- Тесты: PHPUnit 11 или Pest

## Команды
```bash
composer install
composer test            # phpunit/pest
vendor/bin/phpstan analyse
vendor/bin/php-cs-fixer fix --dry-run --diff
composer audit
```

## Конвенции
- `declare(strict_types=1);` в каждом файле
- Типизация свойств, параметров и возвращаемых значений; `mixed` — только осознанно
- Сервисы — через конструктор (DI), без глобального состояния
- Исключения домена вместо кодов возврата; не глотать ошибки
- SQL — только prepared statements/Doctrine; вывод в шаблонах — с экранированием
- Загрузка файлов: проверка через `finfo_file`, ограничение размера и типа, хранение вне webroot

## Проверка
```bash
php -v && composer validate --strict && vendor/bin/phpstan analyse
```
