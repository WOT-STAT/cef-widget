# Wotstat Widgets

Мод для отображения браузерных виджетов в игре World of Tanks и Мир Танков.

> README скоро перепишу.  

## Возможности
- **Добавление виджетов** по URL и из локальных файлов
- **DevTools** для открытых виджетов (нужно прописывать в конфиге и перезапускать игру)
- **Изменение размера** в двух режимах, зависит от мета тега страницы
  - Произвольное изменение высоты/ширины
  - Изменение ширины, а высота подстраивается под высоту страницы
- **Блокировка виджета** – не даёт его случайно сдвинуть, делает прозрачным для кликов
- **Перезагрузка** страницы с отключенным кешем страницы
- **Минимизация** виджета –  виджет всё ещё выполняется, но не отправляется на клиент (почти не тратит ресурсов компа)
- Возможно накликать **разные размеры/позиции для боя и ангара**
- Виджеты **сохраняются при перезапуске** игры

## Инструкция для разработчиков виджетов

> Вам пока рано.  
> Скоро появится инструкция и DataProvider

Режим автоматической высоты включается мета-тегом:

```html
<!DOCTYPE html>
<html>
  <head>
    <meta name="wotstat-widget:auto-height">
  </head>
</html>
```

## Сборка мода из исходников

Сборка осуществляется с помощью `bash` скрипта `build.sh` в корне проекта.
Поддерживаются опции:
- `-v 0.0.1` - версия мода
- `-d` - отладочная сборка
- `-p` – сборка только только Python (при условии что CEF и AS3 уже собраны)
- `-s` – сборка CEF + Python (при условии что AS3 уже собран)
- `-a` – сборка AS3 + Python (при условии что CEF уже собран)

Можно комбинировать, например:
```bash
# Соберёт Python и CEF сервер, AS3 возьмёт из кеша
./build.sh -v 0.0.1 -d -ps
```


Мод состоит из трёх частей:
- Отдельный процесс `CEF сервера` на котором будут крутиться браузеры. CEF – Chromium Embedded Framework (буквально браузер Chrome с которым можно взаимодействовать через код).  
  Используется версия `v123.0.7+chromium-123.0.6312.46`. Собрана вручную из [PR#669](https://github.com/cztomczak/cefpython/pull/669) в ветке `cefpython123`.
- Мод на `Python2.7` для взаимодействия с игрой, графикой и `CEF сервером`
- Графический интерфейс на `ActionScript 3` для отображения виджетов

