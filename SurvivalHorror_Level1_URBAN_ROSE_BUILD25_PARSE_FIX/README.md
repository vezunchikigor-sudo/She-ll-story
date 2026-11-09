# She-ll-story

3D-шутер от третьего лица в духе Resident Evil. Godot 4.7.2, Android.

> Статус: разработка, v1.0 в процессе. План работ и Definition of Done — в [PLAN.md](PLAN.md).

## Запуск из редактора

1. Godot 4.7.2 → **Import** → выбрать `project.godot` в корне репозитория.
2. **F5** — запустить проект.

## Управление

| Действие | Десктоп | Android |
|---|---|---|
| Идти | WASD | левый стик |
| Осмотреться | мышь | правый стик |
| Огонь | ЛКМ | кнопка «Огонь» |
| Перезарядка | R | кнопка «Перезарядка» |
| Взаимодействие | E | кнопка «Действие» |
| Инвентарь | Tab | кнопка «Инвентарь» |
| Пауза | Esc | кнопка «Пауза» |

*(заполняется по мере готовности)*

## Структура

```
project.godot          настройки проекта
PLAN.md                план выхода на v1.0
docs/references/       референсы моделей
docs/map/              карта 1-го этажа
scripts/               игровые скрипты
scenes/                сцены
art/                   модели и анимации (Rokoko)
mobile/                мобильный HUD и управление
```

## Экспорт для Android

Экспорт выполняется локально через Godot 4.7.2:

1. **Project → Export** → выбрать пресет `Android`.
2. **Project → Install Android Build Template** (один раз), затем указать путь
   к Android SDK и JDK в **Editor Settings**.
3. Для релиза — собрать ключ: **Editor Settings → Export → Android → Debug Keystore**
   или свой release-keystore.
4. Экспортировать APK / AAB.

> `export_presets.cfg` намеренно не в репозитории: в нём параметры keystore.
> Файл должен существовать локально в корне проекта.

## Особенности

- **Анимации — только Rokoko.** Ретиargeting на скелет персонажа через
  `Skeleton3D.bone_map` + `AnimationTree` с `AnimationNodeStateMachine`.
- **Камера от третьего лица.** Захват мыши (`Input.mouse_mode = CAPTURED`) на Android
  не используется: прицел — экранная точка, стрельба — рейкаст от камеры.
- **Мобильные настройки:** `stretch/mode=canvas_items`, `aspect=expand`,
  ориентация — landscape, `emulate_touch_from_mouse=true` для проверки тач-UI в редакторе.
