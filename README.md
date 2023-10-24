# jail_csgo

## RU

### [jailwarden.sp](https://github.com/Alart7471/jail_csgo/blob/main/jailwarden.sp) - ядро плагина, подтягивает за собой файлы из jw_modules, включает:
- Система командиров, меню командира, функции взаимодействия командира с игроками
- Ноблок, мут команды охраны, подзатыльник, фридей
- Система смены скинов определенным группам игроков
- Кастомные админ панели разных уровней
- Автобаланс команд
- Тестовые команды для дебага
- Система персональных внутриигровых идентификаторов (id)
- Вся работа с базой данных игроков, их id, рангов (уровней), опыта
- Логирование последних входов, запоминание IP
- Проверка уровня прав доступа игрока, игрок/админ и т.д.
- Отслеживание всех действий на сервере, занесение всего в статистику
- Начало/конец раунда, смерть/убийство игрока/игроком, детект использования команд
- (Х) Система личных сообщений между игроками (реализована на 50%, есть сомнения в необходимости)

- vip.sp (модуль) - ядро для VIP игроков, включает:
	- идентификацию VIP игроков, проверку в базе данных
	- выдачу персональных скинов
	- пассивное усиление свойств игрока в начале каждого раунда (скорость, здоровье и т.д.)
	- выдачу VIP статуса для админов, удаление VIP статуса для админов
	- тестовую выдачу первого VIP статуса игроку

	- commands.sp (модуль) - список команд для пользователей:
		- команды, доступные всем игрокам: сменить команду, перейти в наблюдатели,
		получить свой SteamID, SteamID64, ссылки на сервер Discord, VK, сайт,
		узнать текущее время, правила сервера
		- админская команда для чата
		- админский функционал для перезапуска раунда командой
		- реклама на сервере (MOTD), вывод сообщений каждые 30-60 секунд

- shop.sp - реализация игрового магазина, включает:
	- открытие и отрисовку меню магазина
	- покупку предметов и их выдачу
	- операции с валютой "кредиты", сохранение в базе данных, начисление призовых кредитов
	- (X) система казино (полностью реализована, требует балансировки, сейчас отключена)

## EN

### [jailwarden.sp](https://github.com/Alart7471/jail_csgo/blob/main/jailwarden.sp) is the core of the plugin, pulling files from jw_modules, which includes:
- Commander's system, commander's menu, and functions for commander's interaction with players
- Noblock, mute commands for the guard team, slap on the head, free
- Skin change system for certain groups of players
- Custom admin panels of different levels
- Auto-balance of teams
- Test commands for debugging
- Personal in-game identification system (ID)
- All player data management, including IDs, ranks (levels), and experience, stored in a database
- Logging of recent logins and IP memory
- Access rights verification for players, admins, etc.
- Tracking of all server actions and recording them in statistics
- Round start/end, player death/kill, detection of command usage
- Partially implemented system for personal messages between players (50% complete, doubts about necessity)

- vip.sp (module) - core for VIP players, including:
  - identification of VIP players, database check
  - issuance of personal skins
  - passive enhancement of player properties at the beginning of each round (speed, health, etc.)
  - issuance of VIP for admins, removal of VIP for admins
  - test issuance of the first VIP to a player

- commands.sp (module) - a comprehensive list of user information commands:
  - commands available to all players: change sides, go to spectators,
    get your SteamID, SteamID64, find server links for Discord, VK, website,
    get the current time, find server rules
  - admin command for chat
  - admin functionality to restart the round with a separate command
  - server advertising (MOTD) with messages displayed every tick (30sec-60sec)

- shop.sp - implementation of a game shop, including:
	- opening and rendering of the shop menu
	- purchase of items and their distribution
	- operations with currency "credits", storing in the database, awarding prize credits at the end of the round
	- (X) casino system (fully implemented, requires balancing adjustments, currently disabled)