Handle g_timerMotd;
int g_motdCounter;

public void Commands_OnPluginStart()
{
	RegConsoleCmd("sm_kill", KillYourself);
	RegConsoleCmd("sm_t", SwitchSideT);
	RegConsoleCmd("sm_spec", SwitchSideSpec);
	RegConsoleCmd("sm_spectator", SwitchSideSpec);
	RegConsoleCmd("sm_spc", SwitchSideSpec);
	//RegConsoleCmd("sm_ct", SwitchSideCT); // Зайти за КТ командой, в меню не прописаны вопросы по правилам и их выбор.
	RegConsoleCmd("sm_steamid", GetSteamID); // Узнать свой стимайди командой
	RegConsoleCmd("sm_steamid64", GetSteamID64); //Test id64
	RegConsoleCmd("sm_site", ShowSite);
	RegConsoleCmd("sm_ds", ShowDiscord);
	RegConsoleCmd("sm_discord", ShowDiscord);
	
	RegConsoleCmd("sm_rules", ShowRules);
	RegAdminCmd("sm_killall", KillAllPlayers, ADMFLAG_ROOT, "");
	//RegConsoleCmd("sm_sct", SilenceCtBan);
	RegConsoleCmd("sm_vk", ShowVk);
	RegConsoleCmd("sm_time", ClientTimeGetF);
	
	AddCommandListener(Event_PlayerPing,"player_ping");   
	AddCommandListener(Event_PlayerPing,"chatwheel_ping");  
	RegConsoleCmd("sm_z", SmZ);
	
	//HookEvent("round_start", Event_RoundStart);
	//HookEvent("round_end", Event_RoundEnd);
	
}

public void Commands_OnMapStart()
{
	g_motdCounter = 1;
}

void Commands_Event_RoundStart(/*Event event, const char[] name, bool dontBroadcast*/)
{
	g_timerMotd = CreateTimer(15.0, Chat_Motd, _, TIMER_FLAG_NO_MAPCHANGE); // 
}

public Action Event_PlayerPing(client, const String:command[], args)
{return Plugin_Stop;} //метки нахуй

void Commands_Event_RoundEnd(/*Event event,const char[] name, bool dontBroadcast*/)
{
    //LogMessage("Round ended, gtimer Checking");
    if(g_timerMotd != null)
    {
        //LogMessage("gtimer != null, TRY TO KILL");
        //KillTimer(g_timerMotd);
        g_timerMotd = null;
        //LogMessage("gtimer = null, KILLED");
    }
    //LogMessage("EndIf roundend");
	//LogMessage("RoundEnd counter - %i", g_motdCounter);
}


Action Chat_Motd(Handle timer)
{
	//LogMessage("START counter - %i", g_motdCounter);
	if(g_motdCounter >= 11)
		g_motdCounter = 1;
	else
		g_motdCounter++;
	//int rnd = GetRandomInt(1, 10);
	switch(g_motdCounter)
	{
		case 1:
		{
			//LogMessage("Message 1");
			CGOPrintToChatAll("Правила можно почитать в дискорде или в нашей группе вк - {GREEN}vk.com/unnamed_jb");
		}
		case 2:
		{
			//LogMessage("Message 2");
			CGOPrintToChatAll("Чтобы играть за СТ необходимо иметь большой ранг!");
		}
		case 3:
		{
			//LogMessage("Message 3");
			CGOPrintToChatAll("Узнать информацию об игроке - {GREEN}!id");
		}
		case 4:
		{
			//LogMessage("Message 4");
			CGOPrintToChatAll("Наш дискорд - {GREEN}discord.gg/4FNHy26Gdu");
		}
		case 5:
		{
			//LogMessage("Message 5");
			CGOPrintToChatAll("Главный администратор: {LIME}Alart747 {DEFAULT}| Номер {GREEN}2");
			//CGOPrintToChatAll("Главный администратор: {LIME} ОФФНИК В СТОНИКЕ {DEFAULT}| Номер {GREEN}3");
		}
		case 6:
		{
			//LogMessage("Message 6");
			CGOPrintToChatAll("Узнать свой ID - {GREEN}!n");
		}
		case 7:
		{
			//LogMessage("Message 7");
			CGOPrintToChatAll("Открыть магазин - {GREEN}!shop");
		}
		case 8:
		{
			//LogMessage("Message 8");
			for(int i = 1; i <= MaxClients; i++)
			{
				if(IsClientValid(i))
				{
					if(GetClientTeam(i) == CS_TEAM_T)
					{
						CGOPrintToChat(i, "Узнать, кто сейчас командир - {GREEN}!w");
					}
					else if(GetClientTeam(i) == CS_TEAM_CT)
					{
						CGOPrintToChat(i, "Чтобы взять командира - напишите {GREEN}!w");
					}
					else
					{
						CGOPrintToChat(i, "Узнать, кто сейчас командир - {GREEN}!w");
					}
				}
			}
		}
		case 9:
		{
			//LogMessage("Message 9");
			CGOPrintToChatAll("За покупкой привилегий пишите в группу вк - {GREEN}!vk");
		}
		case 10:
		{
			//LogMessage("Message 10");
			CGOPrintToChatAll("Узнать свой ранг - {GREEN}!id");
		}
		case 11:
		{
			//LogMessage("Message 11");
			CGOPrintToChatAll("Опробовать {GREEN}VIP {DEFAULT}статус - {GREEN}!testvip");
		}
	}
	//LogMessage("IF g_timer != null, CHECK");
	if(g_timerMotd != null)
	{
		//LogMessage("Timer != null, try to KILL");
		KillTimer(g_timerMotd);
		g_timerMotd = null;
		//LogMessage("Timer = null, KILLED");
	}
	//LogMessage("Timer check finish, creating new timer");
	//LogMessage("END counter - %i", g_motdCounter);
	g_timerMotd = CreateTimer(40.0, Chat_Motd, _, TIMER_FLAG_NO_MAPCHANGE);
}

/* //!ct с вопросами по правилам и перекидкой за CT
int SwitchSideMenuHandle(Menu SwitchSideMenu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_Display:
		{
            char szTitle[128];
            FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            (view_as<Panel>(args)).SetTitle(szTitle); // iItem имеет тип int, его нужно привести к типу Panel и использовать метод SetTitle для установки заглавия.
        }
		
	}
	
}
*/

public Action ShowSite(int client, int args)
{
	CGOPrintToChatAll("Адрес нашего сайта: {GREEN}discord.gg/4FNHy26Gdu{GREEN}");
}

public Action ShowDiscord(int client, int args)
{
	CGOPrintToChatAll("Discord: {GREEN}discord.gg/4FNHy26Gdu{GREEN}");
}

public Action ShowRules(int client, int args)
{
	CGOPrintToChatAll("{DEFAULT}Jailbreak: Правил можно почитать тут: {OLIVE}clck.ru/akez3");
}

public Action ShowVk(int client, int args)
{
	CGOPrintToChatAll("Наша группа VK - {GREEN}vk.com/unnamed_jb");
}
public Action SmZ(int client, int args) //Перекинуть sm_z в jailwarden и проверять админдоступ (gates)
{
	if(GetAdminPriority(GetAdminStatus(client)) > 1)
	{
		if(args != 0)
		{
			char message[192];
			GetCmdArgString(message, 192);
	
			char name[35];
			GetClientName(client, name, 35);
	
			CGOPrintToChatAll("%s: {OLIVE}%s", name, message); 
			//LogMessage("[!z] %N(%i) - %s", client, GetId(client), message);
		}
		else
		{
			CGOPrintToChat(client, "{GREEN}[!admin] {DEFAULT}Использование: !z <текст>");
		}
	}
}


public Action GetSteamID(int client, int args)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);
	
	char name[35];
	GetClientName(client, name, 35);
	
	CGOPrintToChatAll("{GREEN}SteamID игрока %s:{DEFAULT} %s", name, steamid);
}

public Action GetSteamID64(int client, int args)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_SteamID64, steamid, 32);
	
	
	char name[35];
	GetClientName(client, name, 35);
	
	CGOPrintToChatAll("{GREEN}SteamID64 игрока %s:{DEFAULT} %s", name, steamid);
}


public Action KillYourself(int client, int args)
{
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == CS_TEAM_T)
			{
				char name[35];
				GetClientName(client, name, 35);

				ForcePlayerSuicide(client);
				CGOPrintToChatAll("{PURPLE}Тюремные слухи{DEFAULT}: Зек %s вскрылся.", name);
				return Plugin_Handled;
			}
			if(GetClientTeam(client) == CS_TEAM_CT)
			{
				char name[35];
				GetClientName(client, name, 35);

				ForcePlayerSuicide(client);
				CGOPrintToChatAll("{PURPLE}Тюремные слухи{DEFAULT}: Охранник %s не справился.", name);
				return Plugin_Handled;
			}
			else
			{
				return Plugin_Handled;
			}
		}
		else
		{
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Handled;
	}
}
	





public Action SwitchSideT(int client, int args)
{
	if (GetClientTeam(client) != CS_TEAM_T)
	{
		ChangeClientTeam(client, CS_TEAM_T);		
	}
}

public Action SwitchSideSpec(int client, int args)
{
	if (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
	{
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);		
	}
}

/* //!ct с вопросами по правилам и перекидкой за CT
public Action SwitchSideCT(int client, int args)
{
	Menu menu = new Menu(SwitchSideMenuHandle);
	menu.SetTitle("Rules");
	menu.AddItem("item1", "Пункт 1",ITEMDRAW_DISABLED);
	menu.AddItem("item2", "Пункт 2",ITEMDRAW_DISABLED);
	menu.AddItem("item3", "название",ITEMDRAW_DISABLED );
	menu.AddItem("item4", "Пункт 4");
	menu.AddItem("item5", "Пункт 5", ITEMDRAW_DISABLED);
	if (GetClientTeam(client) != CS_TEAM_CT)
	{
		CGOPrintToChatAll("CT");
		
		menu.Display(client, MENU_TIME_FOREVER);
		
		//ChangeClientTeam(client, CS_TEAM_CT);
	}
}
*/





public Action KillAllPlayers(int client, int args)
{
	if(GetId(client) == 1 || GetId(client) == 11)
	{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
			{
				char name[32];
				GetClientName(i, name, 32);
				
				ForcePlayerSuicide(i);
				CGOPrintToChatAll("{BLUE}[Covid-19] {DEFAULT}Игрок %s умер от короновируса.", name);
			}	
		}
	}
	}
}

int Silence_AdmCt_menu(Menu menuu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			(view_as<Panel>(arg2)).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			
			
			
			char info[32];
			menuu.GetItem(arg2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char name[32];
			GetClientName(cid, name, 32);
			
			char f_name[32];
			GetClientName(client, f_name, 32);
			
			ChangeClientTeam(cid, CS_TEAM_T);
			
			
		}
	}
}



stock Action SilenceCtBan(int client, int args)
{
	char name[32];
	GetClientName(client, name, 32);
	
	Menu menuu = new Menu(Silence_AdmCt_menu);
	menuu.SetTitle("Заблокировать за СТ");
	
	for(int i = 0; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			char cid[8];
			IntToString(i, cid, 8);
			menuu.AddItem(cid, name);
		}
	}
}



/*
int GetId(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect to db: %s", error);
	}
	else 
	{	
		if(IsClientValid(client))
		{
			char steamid64[64];
			GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
			char buffer[255];
			Format(buffer, 255, "SELECT `id` FROM `id` WHERE `steamid64` = '%s'", steamid64);
			DBResultSet query = SQL_Query(db, buffer);
			if (query == null)
			{
				PrintToServer("SQL Query errored (GetId(%d))", client);
			}
			else
			{
				while (SQL_FetchRow(query))
				{
					return SQL_FetchInt(query, 0);
				}	
			
				delete query;
			}
		}
		return -1;
	}
	delete db;
	return -1;
}
*/
public Action ClientTimeGetF(int client, int args)
{
	CGOPrintToChatAll("%f", GetClientTime(client));
}