# jail_csgo

## RU

![jailwarden.sp](https://github.com/Alart7471/jail_csgo/blob/main/jailwarden.sp) - ядро плагина, подтягивает за собой файлы из jw_modules, включает:
-система командиров, меню командира, функции взаимодействия командира с игроками,
ноблок, мут команды охраны, подзатыльник, фридей
-система смены скинов определенным группам игроков
-кастомные админ панели разных уровней
-автобаланс команд
-тестовые комнады для дебага
-система персональных внутриигровых идентификаторов(id)
-вся работа с базой данных игроков, их id, рангов(уровней), опыта,
логирование последних входов, запоминание ip
-проверка уровня прав доступа игрока, игрок/админ итд
-отслеживание всех действий на сервере, занесение всего в статистику,
начало/конец раунда, смерть/убийство игрока/игроком, детект использования команд
х|система личных сообщений между игроками (реализована на 50%, есть сомнения в необходимости)

-vip ядро, операции и проверки для вип игроков
	-идентификация вип игроков, проверка по базе данных
	-выдача персональных скинов
	-пассивное усиление свойств игрока в начале каждого раунда(скорость, кол-во здоровья итд)
	-выдача вип для админов, удаление вип для админов
	-тестовая выдача первой випки игроку
-commands (команды), общий список пользовательских информационных команд
	-команды, доступные каждому игроку - смена стороны, перейти за наблюдаталей,
	получить свой стимайди, стимайди64, узнать ссылки сервера на дискорд, вк, сайт,
	получить текущее время, узнать где находятся правила сервера
	-админская команда для чата
	-админский функционал для перезапуска раунда отдельной командой
	-реклама на сервере(motd), вывод сообщений каждый тик (30сек-60сек)




shop.sp - реализация игрового магазина, включает:
-открытие и отрисовка меню магазина
-покупка предметов, их выдача
-операции с валютой "кредиты", занесение в базу, начилсение по итогам раунда призовых кредитов
x|система казино(реализована полностью, требует балансировочные правки, сейчас выключена)


## EN

### ![jailwarden.sp](https://github.com/Alart7471/jail_csgo/blob/main/jailwarden.sp) is the core of the plugin, pulls files from jw_modules, includes:
-commander's system, commander's menu, commander's interaction functions with players,
nobloc, mutation of the guard team, slap on the head, free
-skin change system for certain groups of players
-custom admin panels of different levels
-auto-balance of commands
-test rooms for debag
-system of personal in-game identifiers (id)
-all work with the database of players, their IDs, ranks (levels), experience,
logging of recent entries, memorizing ip
-checking the level of access rights of the player, player/admin, etc.
-tracking all actions on the server, recording everything in statistics,
the beginning / end of the round, the death / murder of the player / player, the detection of the use
of x commands | the system of personal messages between players (implemented by 50%, there are doubts about the need)

-vip core, operations and checks for VIP players
-identification of VIP players, database check
-issuance of personal skins
	-passive enhancement of the player's properties at the beginning of each round (speed, number of health, etc.)
-issuance of VIP for admins, removal of VIP for admins
	-test issue of the first vipka to the player
-commands, a general list of user information commands
	-commands available to each player - change sides, go to the observer,
get your stimaydi, stimaydi64, find out the server links to discord, vk, website,
get the current time, find out where the server rules are
	-admin team for chat
	-admin functionality for restarting the round with a separate command
-advertising on the server (motd), message output every tick (30sec-60sec)




shop.sp - game store implementation, includes:
-opening and rendering the store menu
-purchase of items, their issuance
-operations with the currency "credits", entering into the database, starting at the end of the round of prize credits
x|casino system(fully implemented, requires balancing edits, now disabled)