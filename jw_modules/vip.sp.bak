int g_admin_must_say_id_to_give_vip[MAXPLAYERS +1];
int m_flLaggedMovementValue;
float g_dSpeed;
bool g_VipUsed[MAXPLAYERS+1];
bool g_VipActive[MAXPLAYERS+1];
Handle g_timerVipActive[MAXPLAYERS +1];
Handle g_timerResetGravity;

int g_MaxHealth[MAXPLAYERS+1];
int g_MaxHealthCanBeRegenerated[MAXPLAYERS+1];	
int g_Iteration[MAXPLAYERS+1];

//Handle g_debugTimerOne;

public void Vip_OnPluginStart()
{
	RegConsoleCmd("sm_cid", Vip_GetId);
	RegConsoleCmd("sm_isvip", Test_VipTest);
	RegConsoleCmd("sm_vip", OpenVipMenu);
	RegConsoleCmd("sm_testvip", Adm_AddTestVip);
	RegConsoleCmd("sm_viptest", Adm_AddTestVip);
	
	m_flLaggedMovementValue = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
	
	RegConsoleCmd("sm_addvip", Adm_AddVip_Gates);
	
	AddCommandListener(Functions_Say, "say"); //Святой сказал так
	AddCommandListener(Functions_Say, "say2");
	AddCommandListener(Functions_Say, "say_team");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i))
			g_admin_must_say_id_to_give_vip[i] = 0;
	}
}


public Action Vip_GetId(int client, int args)
{
	PrintToChat(client, "Name %N, ID: %i",client,GetId(client));
}

//VIP STATUS 0 - випки нету(закончилась), 1 - вип активна(на время), 2 - вип активна, навсегда


public bool IsPlayerVip(int client)
{
	/*
	int vipstatus;
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	if(db == null)
	{
		PrintToServer("IsPlayerVip not connect: %s", error);
	}
	else
	{
		
		char buffer[255];
		Format(buffer, sizeof(buffer), "SELECT `status` FROM `vip_users` WHERE `id` = '%i'", GetId(client));
		DBResultSet query = SQL_Query(db, buffer);
		if (query == null)
		{
			PrintToServer("SQL Query errored (GetId(%d))", client);
		}
		else
		{
			while (SQL_FetchRow(query))
			{
				vipstatus = SQL_FetchInt(query, 0);
			}	
		
			delete query;
		}
	}*/
	switch(IsPlayerVipStatus(client))
	{
		case 0:
			return false;
		case 1,2:
			return true;
		default:
			return false;
	}
}



public void Vip_Event_RoundStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsPlayerVipStatus(i) == 1)
		{
			UpdateVipTime(i);
		}
		g_VipUsed[i] = false;
		if(IsClientValid(i) && IsClientInGame(i) && IsPlayerVip(i))
		{
			g_VipUsed[i] = false;
			g_VipActive[i] = false;
			g_dSpeed = GetEntDataFloat(i, m_flLaggedMovementValue);
			//CGOPrintToChatAll("gDSPEED = %f", g_dSpeed);
			SetVipAbility(i);
		}
		else
			SetUnVipAbility(i);
		VipAbilitiesRefresh(i);
		
		//if(IsClientValid(i) && IsPlayerVip(i))
		
		
	}
	g_timerResetGravity = CreateTimer(2.0, ReSetVipAbility, _, TIMER_FLAG_NO_MAPCHANGE);
	//CreateTimer(1.0, DebugGravity, _, TIMER_REPEAT);
}



public void Vip_Event_RoundEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsPlayerVip(i))
		{
			UpdateVipTime(i);
		}
		if(IsPlayerVip(i))
			DelVipAbility(i);
		else
			SetUnVipAbility(i);
		VipAbilitiesRefresh(i);
	}
	g_timerResetGravity = null;
	if(g_timerResetGravity != null)
	{
		KillTimer(g_timerResetGravity);
		g_timerResetGravity = null;
	}
}




stock Action DebugGravity(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && IsPlayerVip(i))
		{
			CGOPrintToChatAll("Gravity %N = %f", i, GetEntityGravity(i));
		}
	}
}

public void Vip_Event_PlayerSpawn(int client)
{
	if(IsClientValid(client) && IsClientInGame(client))
	{
		if(IsPlayerVip(client))
		{
			g_VipUsed[client] = false;
			g_dSpeed = GetEntDataFloat(client, m_flLaggedMovementValue);
			//CGOPrintToChatAll("[SPAWN] client - %i", client);
			//CGOPrintToChatAll("[SPAWN] SetAbil %N", client);
			SetVipAbility(client);	
		}
		else
		{
			SetUnVipAbility(client);
		}
	}
	/*
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && IsPlayerVip(i))
		{
			g_VipUsed[i] = false;
			g_dSpeed = GetEntDataFloat(i, m_flLaggedMovementValue);
			SetVipAbility(i);
		}
		VipAbilitiesRefresh(i);
	}
	*/
	//if();
}

public Action UpdateVipTime(int client)
{
	if(IsPlayerVipStatus(client) == 1)
	{
		char error[255];
		Database db = SQL_DefConnect(error,sizeof(error));
	
		char buffer[255];
		Format(buffer, 255, "SELECT `status` FROM `vip_users` WHERE `id` = '%i'", GetId(client));
		DBResultSet query = SQL_Query(db, buffer);
		if(query == null)
		{
			PrintToServer("[UpdateVipTime]query = null, error: %s",buffer);
			delete db;
			return Plugin_Handled;
		}
		else
		{
			Format(buffer, 255, "UPDATE `vip_users` SET `date` = NOW() WHERE `id` = '%i'", GetId(client));
			if (!SQL_FastQuery(db, buffer))
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
			}
			LogMessage("[UpdateVipTime] Игроку %N обновлено время VIP", client);
			DelVipIfEnded(client);

			delete query;
			delete db;
			return Plugin_Handled;
		}
	}
	else
	{
		return Plugin_Handled;
	}
}

int IsPlayerVipStatus(int client)
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
			int temp_int;
			char buffer[255];
			Format(buffer, 255, "SELECT `status` FROM `vip_users` WHERE `id` = '%i'", GetId(client));
			DBResultSet query = SQL_Query(db, buffer);
			if (query == null)
			{
				PrintToServer("SQL Query errored (GetId(%d))", client);
				delete query;
				delete db;
			}
			else
			{
				while (SQL_FetchRow(query))
				{
					temp_int = SQL_FetchInt(query, 0);
					delete query;
					delete db;
					return temp_int;
				}
			}
		}
		delete db;
		return -1;
	}
	delete db;
	return -1;
}

int IsPlayerVipStatusId(int id)
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect to db: %s", error);
	}
	else 
	{
		//if()
		//{
			int temp_int;
			char buffer[255];
			Format(buffer, 255, "SELECT `status` FROM `vip_users` WHERE `id` = '%i'", id);
			DBResultSet query = SQL_Query(db, buffer);
			if (query == null)
			{
				PrintToServer("SQL Query errored (GetId(%d))", id);
			}
			else
			{
				while (SQL_FetchRow(query))
				{
					temp_int = SQL_FetchInt(query, 0);
					delete query;
					delete db;
					return temp_int;
				}	
			
				
			}
		//}
	return -1;
	}
	delete db;
	return -1;
}

public Action DelVipIfEnded(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	char buffer[255];
	Format(buffer, 255, "SELECT `status` FROM `vip_users` WHERE `id` = '%i' AND `date` >= `date_to`", GetId(client));
	DBResultSet query = SQL_Query(db, buffer);
	if(query == null)
	{
		//PrintToServer("[DelVipIfEnded]query = null, error: %s",buffer);
		delete query;
		delete db;
		return Plugin_Handled;
	}
	else
	{
		//PrintToServer("[DelVipIfEnded][156] query != null");
		if(SQL_GetRowCount(query) == 0)
		{
			//LogMessage("[DelVipIfEnded]У игрока %N остается активная випка", client);
			delete db;
			delete query;
			return Plugin_Handled;
			//return 0;
		}
		else
		{
			//LogMessage("[DelVipIfEnded]У игрока %N закончилось время вип!", client);
			DelVipDb(GetId(client));
			delete db;
			delete query;
			return Plugin_Handled;
			//return 1;
		}
	}
}


public Action DelVipDb(int id)
{
	
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	char buffer[255];
	Format(buffer, 255, "UPDATE `vip_users` SET `status` = '0' WHERE `id` = '%i'", id);
	//DBResultSet query = SQL_Query(db, buffer);
	if (!SQL_FastQuery(db, buffer))
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
	LogMessage(buffer);
	LogMessage("[DelVipDb] VIP STATUS %s(%i) - 0",GetName(id), id);
	
	delete db;
	return Plugin_Handled;
}


public Action Adm_AddVip_Gates(int client, int args)
{
	if(GetId(client) == 2 || GetId(client) == 11)
	{
		//CGOPrintToChatAll("ADMIN vip");
		g_admin_must_say_id_to_give_vip[client] = -2; // -2 -ищет IDшку, >0 - нашел
		CGOPrintToChat(client, "Введите ID:\nДля отмены: -1");
	}
	else
	{
		CGOPrintToChat(client, "{RED}Alart747{DEFAULT}: вам недоступна эта команда!");
	}
}



public Action Functions_Say(int client, const char[] buffer, int args)
{
	if(g_admin_must_say_id_to_give_vip[client] == -2)
	{
		char message[32];
		GetCmdArgString(message, sizeof(message));
		StripQuotes(message);
		int choose = StringToInt(message);
		CGOPrintToChat(client, "message - %s", message);
		CGOPrintToChat(client, "choose - %i", choose);
		if(choose > 0)
		{
			g_admin_must_say_id_to_give_vip[client] = choose;
			//if(g_admin_must_say_id_to_give_vip[client]
			CGOPrintToChat(client, "VALUE: %i", g_admin_must_say_id_to_give_vip[client]);
			Adm_OpenAddVipMenu(client, g_admin_must_say_id_to_give_vip[client]);
			return Plugin_Handled;
		}
		else if(choose == -1)
		{
			g_admin_must_say_id_to_give_vip[client] = -1;
			return Plugin_Handled;
		}
	}
	else
		return Plugin_Continue;
}

int Adm_OpenAddVipMenuH(Menu menu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(args).SetTitle(szTitle); 
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(args, info, sizeof(info), style);
			
			
			//CGOPrintToChatAll("DRAWITEM status - %i",status);
			switch(IsPlayerVipStatusId(g_admin_must_say_id_to_give_vip[client]))
			{
				case -1, 0:
				{
					switch(args)
					{
						case 0: return ITEMDRAW_DISABLED;
						case 1,2,3,4,5,6,7: return style;
					}
				}
				case 1:
				{
					switch(args)
					{
						case 0,1,2,3,4,5,6,7: return style;	
					}
				}
				case 2:
				{
					switch(args)
					{
						case 1,2,3,4,5, 6, 7:
							return ITEMDRAW_DISABLED;
						case 0: 
							return style;
					}
				}
			}
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(args, info, sizeof(info));
			int status = -1;
			StringToIntEx(info, status);
			CGOPrintToChat(client, "args - %i, cid - %i", args, status); // status - випстатус
			//CGOPrintToChatAll("Сохраненный чел - %N", g_admin_must_say_id_to_give_vip[client]);
			//args - выбранный пункт меню, cid - status вип(первый передаваемый аргумент из AddItem)
			char buffer[256];
			switch(args)
			{
				case 0: //Снять вип
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 0, 0, client);
					CGOPrintToChat(client, "Попытка снять випку игроку %N", g_admin_must_say_id_to_give_vip[client]); 
					
					/*FormatEx(buffer, sizeof(buffer), "");
					if(!SQL_FastQuery(db, buffer))
					{
						SQL_GetError(db, error, sizeof(error));
						PrintToServer("AdminMask to query 1 (error: %s)", error);
					}*/
				}
				case 1: //1 час
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 0, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 2: //1 день
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 1, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 3: //7 дней
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 2, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 4: //14 дней
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 3, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 5: //30 дней
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 4, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 6: //90 дней
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 1, 5, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
				case 7: // Навсегда
				{
					CreateVipDb(g_admin_must_say_id_to_give_vip[client], 2, 0, client);
					CGOPrintToChat(client, "VIP %i", args);
				}
			}
		}
		case MenuAction_End:
		{
			g_admin_must_say_id_to_give_vip[client] = 0;
			delete menu;
		}
		case MenuAction_Cancel:
		{
			g_admin_must_say_id_to_give_vip[client] = 0;
			
		}
	}
}

public Action Adm_OpenAddVipMenu(int client, int args)
{
	//args - ID игрока для внесения в базу VIP
	//status - VIP статус выбранного игрока
		// -1 --- Дравайтемы все стайл, креаттейбл
		// 	0 --- Дравайтемы все стайл, апдейттейбл
		//  1 --- Дравайтемы все стайл, апдейттейбл
		//  2 --- Временные вип дравайтем дизейбл, апдейттейбл
	if(!(args > MaxId()))
	{
	
	Menu menu = new Menu(Adm_OpenAddVipMenuH, MenuAction_Select|MenuAction_End|MenuAction_DrawItem|MenuAction_Cancel);
	menu.SetTitle("Выдать VIP %s\nID: %i\n", GetName(args), args);
	
	char cStatus[8];
	IntToString(client, cStatus, sizeof(cStatus));
	
	menu.AddItem(cStatus, "Снять VIP");
	menu.AddItem(cStatus, "1 час");
	menu.AddItem(cStatus, "1 день");
	menu.AddItem(cStatus, "7 дней");
	menu.AddItem(cStatus, "14 дней");
	menu.AddItem(cStatus, "30 дней");
	menu.AddItem(cStatus, "90 дней");
	menu.AddItem(cStatus, "Навсегда");
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
	}
	else
	{
		//CGOPrintToChatAll("ELSE");
		CGOPrintToChat(client, "Такой ID в базе отсутствует! Максимальное значение id - %i", MaxId());
		return Plugin_Handled;
	}
}

public Action Test_VipTest(int client, int args)
{
	CGOPrintToChatAll("VIPSTATUS - %i",IsPlayerVipStatus(client));
	CGOPrintToChatAll("Запомнил его - %i", g_admin_must_say_id_to_give_vip[client]);
	if(IsClientValid(g_admin_must_say_id_to_give_vip[client]))
		CGOPrintToChatAll("Это %N", g_admin_must_say_id_to_give_vip[client]);
	CGOPrintToChatAll("MAX - %i", MaxId());
	LogMessage("%N(%i) triggered sm_isvip", client, GetId(client));
}



public Action CreateVipDb(int id, int args1, int args2, int args3)
{
	//id - ID игрока с вип, ранее - client
	//args1 - тип VIP (0 - вип закончился, 1 - вип на время, 2 - вип навсегда)
	//args2 - время вип, если args 1 == 1
		//0 - 1 час
		//1 - 1 день
		//2 - 1 неделя
		//3 - 2 недели
		//4 - 1 месяц
		//5 - 3 месяца
	//args3 - админ, который выдает вип
	
	switch(args1)
	{
		case 0://Поменять вип статус на 0
		{
			CGOPrintToChat(args3, "Вы выбрали снять випку игроку %s", GetName(g_admin_must_say_id_to_give_vip[args3]));
			DelVipDb(id);
			CGOPrintToChatAll("[!admin] %N снял VIP игроку %s", args3, GetName(id));
			LogMessage("Статус VIP изменен игроку %s(%i) на %i", GetName(id), id, args1);
			return Plugin_Handled;
		}
		case 1: // Выдать на время
		{
			char date_buffer[20]; //Исходя из текущего максимального значения текста ниже
			switch(args2)
			{
				case 0:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 HOUR");
				case 1:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 DAY");
				case 2:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 WEEK");
				case 3:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 2 WEEK");
				case 4:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 MONTH");
				case 5:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 3 MONTH");
			}
			
			//CGOPrintToChatAll("VIP status DB -1 IF");
			char error[255];
			Database db = SQL_DefConnect(error,sizeof(error));
	
			if(db == null)
			{
				PrintToServer("CreateBanDb not connect: %s", error);
			}
			else
			{
				char buffer[512]
				switch(IsPlayerVipStatusId(id))
				{
					case -1:
					{
						/*
						char szname[128]
						FormatEx(szname, sizeof(szname), "%s", GetName(id));
						SQL_EscapeString(db
						*/
						Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%s', '%i', NOW(), DATE_ADD(NOW(),%s), 0)", id, GetName(id), args1, date_buffer);
					}
					case 0:
					{
						Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `status` = '%i', `date` = NOW(), `date_to` = DATE_ADD(NOW(),%s) WHERE `id` = '%i'", args1, date_buffer, id);
					}
					case 1:
					{
						Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `date` = NOW(), `date_to` = DATE_ADD(`date_to`,%s) WHERE `id` = '%i'", date_buffer, id);
					}
				}
				
				//char buffer[255];
				//Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%N', '%i')");
				if (!SQL_FastQuery(db, buffer))
				{
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				if(args3 > 0)
					CGOPrintToChatAll("{GREEN}[VIP] {DEFAULT}%N выдал VIP игроку %s", args3, GetName(id));
				else if(args3 == 3)
					CGOPrintToChatAll("{GREEN}[VIP] {DEFAULT} %s активировал {GREEN}!testvip");
				LogMessage(buffer);
				LogMessage("%s(%i) получил VIP на %s", GetName(id), id, date_buffer);
				delete db;
				return Plugin_Handled;
			}
		}
		case 2:
		{
			if(IsPlayerVipStatusId(id) == 0 || IsPlayerVipStatusId(id) == 1)
			{
				char error[255];
				Database db = SQL_DefConnect(error,sizeof(error));
	
				if(db == null)
				{
					PrintToServer("CreateVipDb not connect: %s", error);
				}
				else
				{
					char buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `status` = '%i', `date` = NOW(), `date_to` = 0 WHERE `id` = '%i'", args1, id);
					if (!SQL_FastQuery(db, buffer))
					{
						SQL_GetError(db, error, sizeof(error));
						PrintToServer("Failed to query (error: %s)", error);
					}
					LogMessage("Статус VIP изменен игроку %s(%i) на %i", GetName(id), id, args1);
					delete db;
					return Plugin_Handled;
				}
			}
			else if(IsPlayerVipStatusId(id) == -1)
			{
				char error[255];
				Database db = SQL_DefConnect(error,sizeof(error));
	
				if(db == null)
				{
					PrintToServer("CreateBanDb not connect: %s", error);
				}
				else
				{
				
					char buffer[255];
					Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%s', '%i', NOW(), 0, 0)", id, GetName(id), args1);
					if (!SQL_FastQuery(db, buffer))
					{
						SQL_GetError(db, error, sizeof(error));
						PrintToServer("Failed to query (error: %s)", error);
					}
					LogMessage("%s(%i) занесен в базу VIP, status = %i", GetName(id), id, args1);
					delete db;
					return Plugin_Handled;
				}
			}
			else if(IsPlayerVipStatusId(id) == 2)
			{
				CGOPrintToChat(args3, "У %s уже есть VIP навсегда!", GetName(id));
				return Plugin_Handled;
			}
		}
	}
}



public Action SetVipAbility(int client)
{
	//CGOPrintToChatAll("[SetVipA] client - %i", client);
	//CGOPrintToChatAll("[SetVipA] Name - %N", client);
	CS_SetClientClanTag(client, "[VIP]");
	g_MaxHealth[client] = 100 + CalcRank(GetXP(client)) * 10;
	SetEntityHealth(client, g_MaxHealth[client]);
	SetEntityGravity(client, 0.825);
	
	SetEntDataFloat(client, m_flLaggedMovementValue, 1 * 1.05, true);//1.05
	
	/*
	int weapon;
	if ((weapon = GetPlayerWeaponSlot(client, CS_SLOT_KNIFE)) != -1)
	{
		SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(weapon, "Kill");
	}
	GivePlayerItem(client, "weapon_knife");*/
}

public Action SetUnVipAbility(int client)
{
	if(IsClientValid(client))
	{
		CS_SetClientClanTag(client, "");
		g_dSpeed = GetEntDataFloat(client, m_flLaggedMovementValue);
	}
}

public Action DelVipAbility(int client)
{
	//CGOPrintToChatAll("[DelVipAbility] client - %i", client);
	//CGOPrintToChatAll("[DelVipAbility] Name - %N", client);
	//CGOPrintToChatAll("Вип способности сброшены!");
	CS_SetClientClanTag(client, "[VIP]");
	g_MaxHealth[client] = 100;
	SetEntityGravity(client, 1.0);
	SetEntDataFloat(client, m_flLaggedMovementValue, 1.0, true);
}

int OpenVipMenuH(Menu menu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			
		}
		case MenuAction_Select:
		{	
			switch(args)
			{
				case 0: //heal
				{
					VipAction_Heal(client);
				}
				case 1: //regen
				{
					VipAction_Regen(client);
				}
				case 2: //grava
				{
					VipAction_Gravitation(client);
				}
				case 3: //speed
				{
					VipAction_Speed(client);
				}
				case 4: //снять окрас бунтаря
				{
					VipAction_RemoveRebel(client);
				}
				case 5: //маскировка
				{
					VipAction_Mask(client);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action OpenVipMenu(int client, int args)
{
	//CGOPrintToChat(client, "{RED}[!vip] В разработке...");
	if(IsPlayerVip(client))
	{
		if(IsPlayerAlive(client))
		{
			if(GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_CT)
			{
				if(!g_VipUsed[client])
				{
					Menu menu = new Menu(OpenVipMenuH, MenuAction_Select|MenuAction_End|MenuAction_Cancel);
					menu.SetTitle("Меню VIP");
		
					menu.AddItem("1","Использовать аптечку(+100hp)");
					menu.AddItem("2","Использовать регенерацию(+10hp/15sec)");
					menu.AddItem("3","Использовать гравитацию(10sec)");
					menu.AddItem("4","Использовать супер-скорость(5sec)");
					if(GetClientTeam(client) == CS_TEAM_T)
					{
						menu.AddItem("5","Снять окраску бунтаря");
						menu.AddItem("6","Маскировка(10sec)");
					}
					menu.Display(client, MENU_TIME_FOREVER);
					return Plugin_Handled;
				}
				else
				{
					CGOPrintToChat(client, "{GREEN}[VIP]{DEFAULT} VIP-меню можно использовать лишь один раз за раунд!");
				}
			}
			else
			{
				CGOPrintToChat(client, "{GREEN}[VIP] VIP-меню нельзя использовать, будучи наблюдателем!");
			}
		}
		else
		{
			CGOPrintToChat(client, "{GREEN}[VIP]{DEFAULT} VIP-меню доступно только живым!");
		}
	}
	else
	{
		CGOPrintToChat(client, "Купить VIP можно в нашей группе ВКонтакте - {GREEN}!vk");
	}
}



public Action VipAction_Heal(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы активировали лечение!");
	if (g_MaxHealth[client] - GetClientHealth(client) < 100)
	{
		SetEntityHealth(client, g_MaxHealth[client]);
	}
	else if (g_MaxHealth[client] - GetClientHealth(client) > 100)
	{
		SetEntityHealth(client, GetClientHealth(client) + 100);
	}
	
	g_VipUsed[client] = true;	
	DelVipAbility(client);
}

public Action VipAction_Regen(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы активировали регенерацию!");
	if (GetClientHealth(client) + 150 >= g_MaxHealth[client])
	{
		g_MaxHealthCanBeRegenerated[client] = g_MaxHealth[client];
	}
	else
	{
		g_MaxHealthCanBeRegenerated[client] = GetClientHealth(client) + 150;
	}
	g_Iteration[client] = 0;
	
	CreateTimer(1.0, Vip_RegenerateHP, client, TIMER_REPEAT);
	
	g_VipUsed[client] = true;
	//g_VipActive[client] = true;
}

public Action VipAction_Gravitation(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы активировали гравитацию!");
	SetEntityGravity(client, 0.35);	
	g_VipUsed[client] = true;
	g_VipActive[client] = true;
	g_timerVipActive[client] = CreateTimer(10.0, VipAction_DisableVipGravity, client);
	
}

public Action VipAction_Speed(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы активировали скорость!");
	SetEntDataFloat(client, m_flLaggedMovementValue, 1 * 1.5, true);
	g_VipUsed[client] = true;
	//g_VipActive[client] = true;
	g_timerVipActive[client] = CreateTimer(5.0, VipAction_DisableVipSpeed, client);
}

public Action VipAction_RemoveRebel(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы сняли с себя окраску бунтаря!");
	SetEntityRenderColor(client, 255, 255, 255, 255);
	g_VipUsed[client] = true;
	DelVipAbility(client);
}

public Action VipAction_Mask(int client)
{
	CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы активировали маскировку!");
	SetEntityModel(client, "models/player/custom_player/kuristaja/nanosuit/nanosuitv3.mdl");
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/nanosuit/nanosuit_arms.mdl");
	SetEntityHealth(client, 50);
	
	CreateTimer(10.0, Disable_Mask, client);
	g_VipUsed[client] = true;
	//g_VipActive[client] = true;
}


public Action VipAction_DisableVipGravity(Handle timer, int client)
{
	//CGOPrintToChatAll("VIP стабилизирована гравитация");
	g_timerVipActive[client] = null;
	g_VipActive[client] = false;
	DelVipAbility(client);
}

public Action VipAction_DisableVipSpeed(Handle timer, int client)
{
	//CGOPrintToChatAll("VIP стабилизирована скорость");
	g_timerVipActive[client] = null;
	//g_VipActive[client] = false;
	DelVipAbility(client);
}

public Action Vip_RegenerateHP(Handle timer, int client)
{
	if (g_Iteration[client] == 15)
	{
		DelVipAbility(client);
		KillTimer(timer);
		//g_VipActive[client] = false;
		return;
	}
	
	if (GetClientHealth(client) < g_MaxHealthCanBeRegenerated[client] - 10)
	{
		SetEntityHealth(client, GetClientHealth(client) + 10);
	}
	else
	{
		SetEntityHealth(client, g_MaxHealthCanBeRegenerated[client]);
	}
	
	g_Iteration[client]++;
}

public Action Disable_Mask(Handle timer, int client)
{
	g_VipActive[client] = false;
	//SetEntityModel(client, "models/player/custom/ekko/ekko.mdl");
	SetEntityModel(client, "models/player/custom_player/nf/batmanak/terr_f.mdl");
	SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2_arms.mdl");
	DelVipAbility(client);
}

public void VipAbilitiesRefresh(int i)
{
	if(g_timerVipActive[i] != null)
	{
		KillTimer(g_timerVipActive[i]);
		g_timerVipActive[i] = null;
		g_VipActive[i] = false;
		//CGOPrintToChatAll("Таймер завершен досрочно");
	}
}



public Action Adm_AddTestVip(int client, int args)
{
	if(IsClientValid(client) && IsClientInGame(client))
	{
		if(IsPlayerVipStatus(client) == -1)
		{
			CreateVipDb(GetId(client), 1, 0, 0);
			CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Поздравляем, вы получили тестовую VIP на час!");
		}
		else
		{
			switch(IsPlayerVipStatus(client))
			{
				case 0:
					CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}У вас уже была VIP! Viptest недоступен!");
				case 1:
					CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}У вас есть активная VIP! Viptest недоступен!");
				case 2:
					CGOPrintToChat(client, "{GREEN}[VIP] {DEFAULT}Вы имеете VIP навсегда! Viptest недоступен!");
				default:
					CGOPrintToChat(client, "Поздравляем, вы открыли Америку!\nСвяжитесь с нами и покажите нам это сообщение!");
			}
		}
	}	
}


public Action ReSetVipAbility(Handle timer/*, int client*/)
{
	for(int client = 1; client <= MaxClients; client++){
	if(IsClientValid(client) && IsPlayerAlive(client) && IsPlayerVip(client))
	{
		if(g_VipActive[client] == true)
		{
			//CGOPrintToChatAll("//поставить граву 0.3 ");
			SetEntityGravity(client, 0.35);	
		}
		else if(g_VipUsed[client] == true && g_VipActive[client] == false)
		{
			//CGOPrintToChatAll("//поставить АнВипАбилити");
			SetEntityGravity(client, 1.0);
		}
		else if(g_VipUsed[client] == false)
		{
			//CGOPrintToChatAll("Поставить випабилити");
			SetEntityGravity(client, 0.825);
		}
	}}
	g_timerResetGravity = null;
	g_timerResetGravity = CreateTimer(2.0, ReSetVipAbility, _, TIMER_FLAG_NO_MAPCHANGE);
}


//CreateVipDb по clientid, в качестве первого аргумента
/*
public Action CreateVipDb(int client, int args1, int args2, int args3)
{
	//client - clientid в кске
	//args1 - тип VIP (0 - вип закончился, 1 - вип на время, 2 - вип навсегда)
	//args2 - время вип, если args 1 == 1
	//args3 - админ, который выдает вип
	
	switch(args1)
	{
		case 0://Поменять вип статус на 0
		{
			CGOPrintToChatAll("Вы выбрали снять випку игроку %N", g_admin_must_say_id_to_give_vip[client]);
			DelVipDb(client);
			CGOPrintToChatAll("[!admin] %N снял VIP игроку %N",args3, client );
			LogMessage("Статус VIP изменен игроку %N(%i) на %i", client, GetId(client), args1);
			return Plugin_Handled;
		}
		case 1: // Выдать на время
		{
			char date_buffer[20]; //Исходя из текущего максимального значения текста ниже
			switch(args2)
			{
				case 0:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 HOUR");
				case 1:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 DAY");
				case 2:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 WEEK");
				case 3:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 2 WEEK");
				case 4:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 1 MONTH");
				case 5:
					Format(date_buffer, sizeof(date_buffer), "INTERVAL 3 MONTH");
			}
			
			CGOPrintToChatAll("VIP status DB -1 IF");
			char error[255];
			Database db = SQL_DefConnect(error,sizeof(error));
	
			if(db == null)
			{
				PrintToServer("CreateBanDb not connect: %s", error);
			}
			else
			{
				char buffer[512]
				switch(IsPlayerVipStatus(client))
				{
					case -1:
					{
						Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%N', '%i', NOW(), DATE_ADD(NOW(),%s), 0)", GetId(client), client, args1, date_buffer);
					}
					case 0:
					{
						Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `status` = '%i', `date` = NOW(), `date_to` = DATE_ADD(NOW(),%s) WHERE `id` = '%i'", args1, date_buffer, GetId(client));
					}
					case 1:
					{
						Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `date` = NOW(), `date_to` = DATE_ADD(`date_to`,%s) WHERE `id` = '%i'", date_buffer, GetId(client));
					}
				}
				
				//char buffer[255];
				//Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%N', '%i')");
				if (!SQL_FastQuery(db, buffer))
				{
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				LogMessage(buffer);
				LogMessage("%N(%i) получил VIP на %s", client, GetId(client), date_buffer);
				delete db;
				return Plugin_Handled;
			}
		}
		case 2:
		{
			if(IsPlayerVipStatus(client) == 0 || IsPlayerVipStatus(client) == 1)
			{
				char error[255];
				Database db = SQL_DefConnect(error,sizeof(error));
	
				if(db == null)
				{
					PrintToServer("CreateVipDb not connect: %s", error);
				}
				else
				{
					char buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE `vip_users` SET `status` = '%i', `date` = NOW(), `date_to` = 0 WHERE `id` = '%i'", args1, GetId(client));
					if (!SQL_FastQuery(db, buffer))
					{
						SQL_GetError(db, error, sizeof(error));
						PrintToServer("Failed to query (error: %s)", error);
					}
					LogMessage("Статус VIP изменен игроку %N(%i) на %i", client, GetId(client), args1);
					delete db;
					return Plugin_Handled;
				}
			}
			else if(IsPlayerVipStatus(client) == -1)
			{
				char error[255];
				Database db = SQL_DefConnect(error,sizeof(error));
	
				if(db == null)
				{
					PrintToServer("CreateBanDb not connect: %s", error);
				}
				else
				{
				
					char buffer[255];
					Format(buffer, sizeof(buffer), "INSERT INTO `vip_users` (`counter`, `id`, `name`, `status`, `date`, `date_to`, `date_left`) VALUES (NULL, '%i', '%N', '%i', NOW(), 0, 0)", GetId(client), client, args1);
					if (!SQL_FastQuery(db, buffer))
					{
						SQL_GetError(db, error, sizeof(error));
						PrintToServer("Failed to query (error: %s)", error);
					}
					LogMessage("%N(%i) занесен в базу VIP, status = %i", client, GetId(client), args1);
					delete db;
					return Plugin_Handled;
				}
			}
			else if(IsPlayerVipStatus(client) == 2)
			{
				CGOPrintToChat(args3, "У %N уже есть VIP навсегда!", client);
				return Plugin_Handled;
			}
		}
	}
}



*/