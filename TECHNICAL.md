# Technical Reference

## Collision Layers

| Layer | Bitmask | Name           |
| ----- | ------- | -------------- |
| 1     | 1       | walls          |
| 2     | 2       | player         |
| 3     | 4       | enemies        |
| 4     | 8       | player_bullets |
| 5     | 16      | enemy_bullets  |
| 6     | 32      | swat           |
| 7     | 64      | blood          |
| 8     | 128     | furniture      |

## Collision Masks

| Entity         | Mask | Hits                          |
| -------------- | ---- | ----------------------------- |
| Player bullets | 5    | walls + enemies               |
| Enemy bullets  | 3    | walls + player                |
| Player/enemies | 129  | walls + furniture (bullets pass through furniture) |
| SWAT           | 131  | walls + player + furniture    |
| Casings        | 129  | walls + furniture             |

## Dynamic Music

`MusicManager` (autoload) keeps five stems playing in sync and cross-fades between states in 0.25 s.

| State     | drums | bass_groove | bass_low | guitar_chords | guitar_notes |
| --------- | :---: | :---------: | :------: | :-----------: | :----------: |
| MENU      |       |             | ✓        |               | ✓            |
| PRE_FIGHT |       | ✓           |          |               |              |
| FIGHT     | ✓     | ✓           |          |               |              |
| DIALOGUE  |       | ✓           |          |               | ✓            |
| CLEANUP   | ✓     |             | ✓        | ✓             | ✓            |
| SILENT    |       |             |          |               |              |

FIGHT state activates when at least one enemy is in aggro. RESULT state freezes the current mix.
