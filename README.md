# Bottom-Down Maid (Ratmaid)

![Ratmaid](images/Hakos_Baelz_Maid.jpg "Ratmaid")

Top-down шутер в духе Hotline Miami на Godot 4.6. Горничная-оперативница заходит в помещение по «перехваченному сигналу», отстреливает всех присутствующих, потом замётывает следы: прячет трупы в мусорный бак, моет кровь шваброй и уходит до прихода спецназа.

## Фазы уровня

1. **INTRO** — реплика горничной, управление заблокировано.
2. **COMBAT** — стрельба по болванчикам. Один выстрел в любую сторону = смерть (и у горничной, и у врагов).
3. **DIALOGUE** — перехваченный сигнал и команда «CLEAR OUT». Управление снова заблокировано.
4. **CLEANUP** — таймер, уборка. Переключение на швабру, подбор/сброс трупов в ведро, мойка крови. Уйти через дверь можно только если всё чисто.
5. **WIN / LOSE** — выйти чистым → победа; с уликами или по истечении таймера → поражение (приходит спецназ).

## Управление

| Действие          | Клавиатура/мышь    | Геймпад          |
| ----------------- | ------------------ | ---------------- |
| Ходьба            | WASD / стрелки     | Левый стик       |
| Прицел            | Мышь               | Правый стик      |
| Огонь             | ЛКМ / Пробел       | RT / R1          |
| Подобрать/бросить | E                  | A / × (Cross)    |
| Швабра ↔ Пистолет | Tab                | D-pad ↑          |
| Меню / продолжить | Enter / Space      | A / × (Cross)    |
| Отмена            | Esc                | B / ○            |

## Сложности

Переключаются в главном меню (кольцевая кнопка):

- **ОБЫЧНАЯ** — таймер уборки 35 сек, для победы достаточно убрать трупы и кровь.
- **СЛОЖНАЯ** — таймер 30 сек, плюс нужно собрать все стреляные гильзы шваброй.

Выбор сохраняется в `user://settings.cfg`.

## Локализация

Русский и английский языки. Переключатель в главном меню (кольцевая кнопка, RU → EN → ...). Строки лежат в `localization/strings.csv` (импортируется Godot в `.translation` при первом открытии проекта). Тексты в коде — через `tr("key")`.

Важные ключевые слова сохраняют двойной смысл:
- **УБИРАТЬСЯ / ПРИБРАТЬСЯ → CLEAR OUT** (убрать грязь / сваливать)
- **СИГНАЛ → SIGNAL** (радио / бэкдор-сообщение)

## Структура проекта

```
scenes/
  menu/main_menu.tscn       главное меню (Start, Quit, RU/EN, Difficulty)
  levels/level_01.tscn      арена с TileMapLayer пола/мебели
  player/player.tscn        CharacterBody2D, камера, дула, InteractionArea
  bullet/bullet.tscn        Area2D-пуля
  enemy/enemy.tscn          CharacterBody2D + VisibleOnScreenNotifier2D
  enemy/enemy_bullet.tscn   Area2D-пуля врага
  enemy/swat_enemy.tscn     неуязвимый спецназ (приходит по таймауту)
  corpse/corpse.tscn        труп с PickupArea и скольжением от импульса
  props/
    blood_splatter.tscn     растущее пятно крови, моется шваброй
    blood_spray.tscn        CPUParticles2D, одноразовый всплеск при попадании
    trash_bin.tscn          мусорный бак: DepositArea + StaticBody2D
    casing_player.tscn      гильза игрока (RigidBody2D)
    casing_enemy.tscn       гильза врагов (RigidBody2D)
  ui/
    hud.tscn                таймер (красный), режим оружия, подсказки, экран результата
    dialogue_box.tscn       типограф с отдельными AudioStreamPlayer на спикера
    exit_arrow.tscn         указатель на выход в фазе уборки
  music/music_manager.tscn  autoload, пять синхронных стемов с fade-миксом
scripts/
  main_menu.gd              локаль/сложность, fade-out перед стартом уровня
  level_manager.gd          FSM: INTRO → COMBAT → DIALOGUE → CLEANUP → WIN/LOSE
  player.gd                 движение, прицел, стрельба, швабра, труп-на-руках
  enemy.gd                  wander AI + aggro по рейкасту, sidestep от мебели,
                            активен только когда в пределах 50 px от экрана
  swat_enemy.gd             прямая погоня, бессмертен
  bullet.gd / enemy_bullet.gd
  corpse.gd                 скольжение → три растущих пятна крови
  blood_splatter.gd         рисует круг, queue_free при контакте со шваброй
  blood_spray.gd            авто-queue_free по сигналу finished
  casing.gd                 RigidBody2D, freeze при остановке, моется шваброй
  trash_bin.gd              принимает трупы от игрока
  hud.gd / dialogue_box.gd
  exit_arrow.gd             краевой индикатор с wobble
  music_manager.gd          MENU / PRE_FIGHT / FIGHT / DIALOGUE / CLEANUP / SILENT
  furniture_collision.gd    BitMap.opaque_to_polygons → попиксельная коллизия тайлов
  settings_store.gd         autoload Settings: locale + difficulty
  input_device_tracker.gd   autoload InputDevice: KB vs Xbox vs PS
themes/pixel_theme.tres     системный моноширинный без сглаживания
localization/strings.csv    RU/EN
```

Главная сцена (`run/main_scene`) — `scenes/menu/main_menu.tscn`.

## Слои коллизий

| Слой | Битмаска | Назначение      |
| ---- | -------- | --------------- |
| 1    | 1        | walls           |
| 2    | 2        | player          |
| 3    | 4        | enemies         |
| 4    | 8        | player_bullets  |
| 5    | 16       | enemy_bullets   |
| 6    | 32       | swat            |
| 7    | 64       | blood           |
| 8    | 128      | furniture       |

Маски:
- Пули игрока: `walls + enemies` (5)
- Пули врагов: `walls + player` (3)
- Игрок / враги: `walls + furniture` (129) — пули сквозь мебель пролетают
- SWAT: `walls + player + furniture` (131)
- Гильзы: `walls + furniture` (129)

## Динамическая музыка

`MusicManager` (autoload) держит пять стемов `r_*.ogg` синхронно и крест-фейдит их за 0.25 с между состояниями:

| Состояние | drums | bass_groove | bass_low | guitar_chords | guitar_notes |
| --------- | :---: | :---------: | :------: | :-----------: | :----------: |
| MENU      |       |             | ✓        |               | ✓            |
| PRE_FIGHT |       | ✓           |          |               |              |
| FIGHT     | ✓     | ✓           |          |               |              |
| DIALOGUE  |       | ✓           |          |               | ✓            |
| CLEANUP   | ✓     |             | ✓        | ✓             | ✓            |
| SILENT    |       |             |          |               |              |

Состояние FIGHT активируется, когда хотя бы один враг в аггро.

## Запуск

Открыть проект в Godot 4.6 и нажать F5. При первом запуске редактор автогенерит `localization/strings.{en,ru}.translation` из CSV.

Headless-проверка:
```sh
godot --headless --quit-after 180
```

## Credits

- Движок: **Godot 4.6**
- Музыкальный семпл: использован открытый семпл из свободной библиотеки *(TODO: указать конкретный источник/ссылку/лицензию)*
- Вся остальная графика, код и дизайн — собственные.

## Что дальше (roadmap)

- Заменить плейсхолдер-цветные гильзы на спрайты (`images/ft_cartridge_case*.png` уже частично подложены)
- Дополнительные уровни
- Разнообразие оружия, перезарядка
- Меню паузы и настроек звука
- Больше диалогов и нарратива между уровнями
