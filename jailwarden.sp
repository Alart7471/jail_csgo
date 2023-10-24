#include <sourcemod>
#include <cstrike>
#include <clients>
#include <console>
#include <sdktools>
#include <sdkhooks>
#include <csgo_colors>
//#include <funcommands.sp>
#include <timers>
//#include <jwp> 
#include <lastrequest>
#include <stats>
#include "jw_modules/vip.sp"
#include "jw_modules/commands.sp"


#define VERY_BIG_NUMBER 1000000
#define SOUND_RESPAWN "player/pl_respawn.wav" //
#define CMD_PREFIX		"[SM] "



//GlobalForward hOnCtMenuReady;
//GlobalForward hOnCtMenuCreated;

//TopMenu hCtMenu;


Handle g_TimerOne;
//Handle g_TimerCtBan; //Эта хуйня скорее всего работает не так, как нужно. 
bool wardentaked;
bool roundstarted;
bool g_playerMutedByAdm[MAXPLAYERS+1];
//char wardenname[32];
int wardenid;
int g_fdids[MAXPLAYERS +1];
bool g_isctmutted;
bool g_wardennoblock;
ConVar Cvar_SolidTeamMates;

int g_playerStatus[MAXPLAYERS+1]; // 0 - игрок, 1 - СТ, 2 - Админ, 3 - Гладмин, 4 - Супер


public void OnPluginStart()
{
		
	RegConsoleCmd("sm_w", TakeWarden);
	RegConsoleCmd("sm_d", DebugCommand);
	RegConsoleCmd("sm_id", GetUserIds);
	RegConsoleCmd("sm_n", GetMyId);
	RegAdminCmd("sm_max", Get_MaxId, ADMFLAG_ROOT, "");
	//RegConsoleCmd("sm_pm", SendPrivateMessage); В разработке
	//RegConsoleCmd("sm_ids", GetServerPlayerIds); В разработке
	//RegConsoleCmd("sm_save", DebugAction_Save);
	RegConsoleCmd("sm_pudge", SetTestSkin);
	RegConsoleCmd("sm_noblock",Warden_Noblock_User);
	RegConsoleCmd("sm_ct", AdmCt_Gates);
	RegConsoleCmd("sm_refreshnames", Action_RefreshNames);
	RegConsoleCmd("sm_secretcommand", Action_Secretcommand);
	
	
	RegConsoleCmd("sm_admin", CustomAdmin);
	RegConsoleCmd("sm_time", Func_GetTime);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("player_changename", Event_Player_changename);
	HookEvent("player_team", Event_Player_changeteam);
	
	
	//RegAdminCmd("sm_ct", CTPrivilegy, ADMFLAG_CUSTOM1, "");
	RegAdminCmd("sm_setct", SetCTCmd, ADMFLAG_CUSTOM4, "");
	RegAdminCmd("sm_addadmin", Command_AddAdmin, ADMFLAG_CUSTOM5, "");
	//RegAdminCmd("sm_adm", AdminMenu, ADMFLAG_CUSTOM2, "");
	//RegAdminCmd("sm_ct", AdmCt, ADMFLAG_CUSTOM2, "");
	RegAdminCmd("sm_kk", Adm_AfkKick, ADMFLAG_CUSTOM5, "");
	RegAdminCmd("sm_mask", Adm_AdminMask, ADMFLAG_ROOT, "");
	//RegAdminCmd("sm_setvip", Adm_SetVip, ADMFLAG_ROOT, "");
	
	Commands_OnPluginStart();
	Vip_OnPluginStart();
	
	Cvar_SolidTeamMates = FindConVar("mp_solid_teammates");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i))
		{
			g_playerStatus[i] = GetAdminPriority(GetAdminStatus(i));	
		}
	}
}

void OnMapStart()
{
	Commands_OnMapStart();
}

public Action DebugCommand(int client, int args)
{
	//int clientid = GetClientUserId(client);
	//CGOPrintToChatAll("%i", clientid);
	CGOPrintToChatAll("%i",client);
	CGOPrintToChatAll("MaxClients - %i", MaxClients);
	if(IsPlayerVip(client))
		CGOPrintToChatAll("Игрок - вип");
	else
		CGOPrintToChatAll("Игрок - не вип");
}




public void OnClientPostAdminCheck(int client)
{
	//CGOPrintToChatAll("%N присоединился", client);
	//CGOPrintToChatAll("Он - %s ", GetAdminStatus(client));
	//LogMessage("%N присоединился", client);
	//LogMessage("Он - %s ", GetAdminStatus(client));
	
	if(GetId(client) > 0)
	{
		LogMessage("%N присоединился, id - %i", client, GetId(client));
		//char name[64] = GetName(GetId(client));
		LogMessage("Имя %s подгружено игроку %N", GetName(GetId(client)), client);
		SetClientName(client, GetName(GetId(client)));
		if(StrEqual(GetAdminStatus(client), "Игрок без привилегий"))
			CGOPrintToChatAll("Игрок {GREEN}%N {DEFAULT}присоединился", client);
		else
			CGOPrintToChatAll("%s {GREEN}%N {DEFAULT}присоединился", GetAdminStatus(client), client);
		LogMessage("%s {GREEN}%N {DEFAULT}присоединился", GetAdminStatus(client), client);
	}
	else
	{
		char steamid64[64];
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		CGOPrintToChatAll("Игрок {GREEN}%N {DEFAULT}присоединился!", client);
		LogMessage("%N присоединился, steamid - %s", client, steamid64);
	}
	
	
	g_playerStatus[client] = GetAdminPriority(GetAdminStatus(client));
	
	
	//char steamid64[64];
	//GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
	//LogMessage((GetId(client) > 0) ? "%N присоединился, id - %i", client, GetId(client) : "%N присоединился, steamid - %s" ;

	/*
	if(StrEqual(GetAdminStatus(client), "Привилегия СТ"))
	{
		g_playerStatus[client] = 1;
		//CGOPrintToChatAll("95");
		//CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	}
	else if(StrEqual(GetAdminStatus(client), "Администратор"))
	{
		g_playerStatus[client] = 2;
		//CGOPrintToChatAll("95");
		//CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	}
	else if(StrEqual(GetAdminStatus(client), "Главный администратор"))
	{
		g_playerStatus[client] = 3;
		//CGOPrintToChatAll("95");
		//CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	}
	else if(StrEqual(GetAdminStatus(client), "Супер-администратор"))
	{
		g_playerStatus[client] = 4;
		//CGOPrintToChatAll("95");
		//CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	}
	else
	{
		g_playerStatus[client] = 0;
		//CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	}
	CGOPrintToChatAll("Status: %i", g_playerStatus[client]);
	//CGOPrintToChatAll("99");
	*/
	
	//GetAdminStatus(client);
}

public void OnClientDisconnect(int client)
{
	//CGOPrintToChatAll("%N отключился!", client);
	//LogMessage("%N Отключился!", client);
	//CGOPrintToChatAll("OLD %i", g_playerStatus[client]);
	g_playerStatus[client] = 0;
	//CGOPrintToChatAll("NEW %i", g_playerStatus[client]);
	//LogMessage("%N отключился, id - %i", client, GetId(client));
	if(GetId(client) > 0)
	{
		CGOPrintToChatAll("%N отключился", client);
		LogMessage("%N отключился, id - %i", client, GetId(client));
	}
	else
	{
		char steamid64[64];
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		CGOPrintToChatAll("%N отключился", client);
		LogMessage("%N отключился, steamid - %s",client, steamid64);
	}
	LogMessage("%f", GetClientTime(client));
	
	if(Stats_IsDbCreated(client))
	{
		if(Stats_SaveTime(client))
		{
			LogMessage("Время игроку %N сохранено", client);
		}
		else
		{
			Stats_CreateDb(client);
			if(Stats_ShowTime(client))
				LogMessage("Игрок %N занесен в базу, время обновлено",client);
			else
				LogMessage("Игроку %N не создана запасная база или время не обновлено", client);
		}
	}
}

public Event_Player_changename(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//CGOPrintToChatAll("{RED}Игрок %N попытался сменить ник!", client);
	CreateTimer(1.0, CheckPlayerNameTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}



public Event_Player_changeteam(Handle:event, const String:name[], bool:dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//CGOPrintToChatAll("%N сменил команду!", client);
	CreateTimer(0.2, CheckPlayerNameTimer, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action CheckPlayerNameTimer(Handle timer, int client)
{
	//CGOPrintToChatAll("Из-за игрока {RED}%N {DEFAULT}вызвана проверка имени", client);
	if(IsClientValid(client) && IsClientInGame(client)){
	char name[32];
	GetClientName(client, name, sizeof(name));
	char can_be[32];
	Format(can_be, sizeof(can_be), "Агент %i", GetClientUserId(client));
	//CGOPrintToChatAll("Может быть %s || %s", GetName(GetId(client)), can_be);
	if(StrEqual(name, GetName(GetId(client))) || StrEqual(name, can_be))
	{
		//CGOPrintToChatAll("Имя игрока {GREEN}%N {DEFAULT}соответствует требованиям", client);
		KillTimer(timer);
	}
	else
	{
		//CGOPrintToChatAll("Имя игрока {RED}%N {DEFAULT}не соответствует требованиям", client);
		Format(name, sizeof(name), "%s", GetName(GetId(client)));
		SetClientName(client, name);
		KillTimer(timer);
	}
	if(IsPlayerVip(client))
	{
		CS_SetClientClanTag(client, "[VIP]");
		//CGOPrintToChatAll("Tag VIP %N", client);
		KillTimer(timer);
	}
	else
	{
		CS_SetClientClanTag(client, "");
		//CGOPrintToChatAll("Tag null %N", client);
		KillTimer(timer);
	}
	return Plugin_Handled;
	}
	else
	{
		return Plugin_Handled;
	}
}
	
public Action TakeWarden(int client, int args)
{
    if(IsClientValid(client) && IsClientInGame(client) && IsPlayerAlive(client))
    {
        if(GetClientTeam(client) == CS_TEAM_CT)
        {
            if(roundstarted == true)
		    {
		    	if(wardentaked == false && IsPlayerAlive(client))
		    	{
		    		wardentaked = true;
		    		wardenid = client;
		    		SetEntityModel(client, "models/player/custom/draven/draven.mdl");
		    		CGOPrintToChatAll("[!w] Игрок {GREEN}%N{DEFAULT} теперь ваш командир!", client);
		    		LogMessage("%N взял командира, id - %i", client, GetId(client));
		    	}
		    	else if(wardentaked == true)
		    	{
		    		if(wardenid == client)
		    		{
		    			OpenWardenMenu(client);
		    		}
		    		else
		    		{
		    		CGOPrintToChat(client,"[!w] Ваш командир - {RED}%N", wardenid);
		    		}
		    	}
		    }
			else
			{
				CGOPrintToChat(client, "[!w] {RED}Сейчас нельзя взять командира!");
			}
        }
        else
        {
            if(wardentaked)
            {
                CGOPrintToChat(client,"[!w] Командир - {RED}%N", wardenid);
            }
            else
            {
                CGOPrintToChat(client, "[!w] {RED}Командир еще не назначен");
            }
            }
    }
    else if(IsClientValid(client) && IsClientInGame(client))
    {
        if(wardentaked)
        {
            CGOPrintToChat(client,"[!w] Командир - {RED}%N", wardenid);
        }
        else
        {
            CGOPrintToChat(client, "[!w] {RED}Командир еще не назначен");
        }
    }
    else if(client == 0)
    {
        if(wardentaked)
        {
            PrintToServer("[!w] Командир - %N", wardenid);
        }
        else
        {
            PrintToServer("[!w] Командир не назначен");
        }
    }
}




bool IsWarden(int client)
{
	return (client == wardenid);
}


void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	
	
	//CGOPrintToChatAll("%i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i",g_fdids[0],g_fdids[1],g_fdids[2],g_fdids[3],g_fdids[4],g_fdids[5],g_fdids[6],g_fdids[7],g_fdids[8],g_fdids[9],g_fdids[10],g_fdids[11],g_fdids[12],g_fdids[13],g_fdids[14],g_fdids[15],g_fdids[16],g_fdids[17],g_fdids[18],g_fdids[19]);
	
	CheckPlayerToFd();
	UnmuteAllCt();
	
	Vip_Event_RoundStart();
	Commands_Event_RoundStart();
	
	CGOPrintToChatAll("Jailbreak: {RED}Микрофоны заключенных отключены на 30 секунд");
}




void Event_RoundEnd(Event event,const char[] name, bool dontBroadcast)
{
	
	
	wardentaked = false;
	roundstarted = false;
	int winner = event.GetInt("winner");
	LogMessage("Раунд закончился, победили %i", winner);
	CGOPrintToChatAll("Раунд закончился");
	UnmuteAllCt();
	//CGOPrintToChatAll("%i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i",g_fdids[0],g_fdids[1],g_fdids[2],g_fdids[3],g_fdids[4],g_fdids[5],g_fdids[6],g_fdids[7],g_fdids[8],g_fdids[9],g_fdids[10],g_fdids[11],g_fdids[12],g_fdids[13],g_fdids[14],g_fdids[15],g_fdids[16],g_fdids[17],g_fdids[18],g_fdids[19]);
	if(g_wardennoblock)
	{
		Warden_Noblock();
	}
	
	if (g_TimerOne != null)
	{
		KillTimer(g_TimerOne);
		g_TimerOne = null;
		
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				SetClientListeningFlags(i, VOICE_NORMAL);			
			}
		}
	}
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT)
			{
				AddXp(i, 1);
			}
			
			if (GetClientTeam(i) == winner)
			{
				if (IsPlayerAlive(i))
				{
					switch (GetClientTeam(i))
					{
						case CS_TEAM_T:
						{
							AddXp(i, 2);
						}
						case CS_TEAM_CT:
						{
							AddXp(i, 3);
							if (IsWarden(i))//Раньше было if (JWP_IsWarden(i))
							{
								AddXp(i, 2);	
							}
						}
					}
				}
			}			
			
		}
	}
	
	Vip_Event_RoundEnd();
	Commands_Event_RoundEnd();
}




void Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	wardentaked = false;
	roundstarted = true;
	g_TimerOne = CreateTimer(30.0, UnmuteAll, _, TIMER_FLAG_NO_MAPCHANGE); //Святой говорил делать так
	
	//CGOPrintToChatAll("[Balance][224]Фризтайм закончился");//debug
	
	LogMessage("Начался новый раунд!");
	
	//баланс без админов и хп(1к2)
	
	float allPlayersCount = 0.0;
	int cts = 0;
	int maxCt = 0;
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientValid(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			{
				if(GetId(i) == 1 || GetId(i) == 17)
				{
					//LogMessage("Игрок %s имеет иммунитет к муту в начале раунда!", name);
				}
				else
				{
					SetClientListeningFlags(i, VOICE_MUTED);
				}
			}
		}
	}
	
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T))
		{
			allPlayersCount++;
		}
	}
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			cts++;
		}
	}
	
	if (allPlayersCount <= 2) 
	{
		maxCt = 1;
	}
	else 
	{
		maxCt = RoundToFloor(allPlayersCount / 3.0);
	}
	
	if (cts <= maxCt)
	{
		//CGOPrintToChatAll("513 return");
	}
	//CGOPrintToChatAll("Баланс....");
	//CGOPrintToChatAll("[Balance][263]cts = %d, maxCt= %d", cts, maxCt); //debug
	int toKick = cts - maxCt;
	//CGOPrintToChatAll("Кикнуть %i", toKick);
	//CGOPrintToChatAll("[Balance][265] ToKick = %d", toKick);//debug
	for (int i = 0; i < toKick; ++i)
	{
		int lowestClient = -1;
		int lowestClientXp = VERY_BIG_NUMBER;
		//CGOPrintToChatAll("[Balance][270] Прошла");//debug
		for (int j = 1; j <= MaxClients; ++j)
		{
			if (IsClientInGame(j) && GetClientTeam(j) == CS_TEAM_CT)
			{				
				int xp = GetXP(j);
				//CGOPrintToChatAll("[Balance][276] Прошла, xp = %d", xp);
				PrintToServer("[RoundFreezeEnd]%d vs %d", GetAdminPriority(GetAdminStatus(lowestClient)), GetAdminPriority(GetAdminStatus(j)));
				PrintToServer("[RoundFreezeEnd]%d vs %d", lowestClientXp, GetXP(j));
				
				if (GetAdminPriority(GetAdminStatus(j)) < GetAdminPriority(GetAdminStatus(lowestClient)))	
				{
					lowestClient = j;
					lowestClientXp = xp;	
				}
				else if (GetAdminPriority(GetAdminStatus(j)) == GetAdminPriority(GetAdminStatus(lowestClient)))
				{
					if (xp <= lowestClientXp)
					{
						lowestClient = j;
						lowestClientXp = xp;						
					}
				}
			}
		}
		//CGOPrintToChatAll("[Balance][295] Прошла, lowestClient = %d", lowestClient);//debug
		LogMessage("%N , id - %i, был переведен за Т автобалансом", lowestClient, GetId(lowestClient));
		ChangeClientTeam(lowestClient, CS_TEAM_T);
		CS_RespawnPlayer(lowestClient);
	}
	//CGOPrintToChatAll("Отбалансил");
	
	if(!wardentaked)
		CreateTimer(30.0, Motd_TakeWarden, _, TIMER_REPEAT);
}

public Action Motd_TakeWarden(Handle timer)
{
	if(!wardentaked && roundstarted)
	{
		//CGOPrintToChatAll("1");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && IsClientInGame(i))
			{
				if(GetClientTeam(i) == CS_TEAM_CT)
				{
					CGOPrintToChat(i, "[!w] {RED}Командир не назначен");
					CGOPrintToChat(i, "[!w] Стать командиром - {GREEN}!w");
				}
			}
		}
	}
	else
	{
		//CGOPrintToChatAll("2");
		KillTimer(timer);
		return;
	}
}




void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	
	

	//-----Убирает оружие при спавне
	int Weapon_Slot;
    for (int i = 0; i < 12; i++)
    {    
        if ((Weapon_Slot = GetPlayerWeaponSlot(client, i)) > 0 && RemovePlayerItem(client, Weapon_Slot))
        {
            AcceptEntityInput(Weapon_Slot, "Kill");
        }
		if ((Weapon_Slot = GetPlayerWeaponSlot(client, i)) > 0 && RemovePlayerItem(client, Weapon_Slot))
        {
            AcceptEntityInput(Weapon_Slot, "Kill");
        }
		if ((Weapon_Slot = GetPlayerWeaponSlot(client, i)) > 0 && RemovePlayerItem(client, Weapon_Slot))
        {
            AcceptEntityInput(Weapon_Slot, "Kill");
        }

    }
    GivePlayerItem(client, "weapon_knife");
	//------
	
	
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	//CGOPrintToChatAll("CLIENT - %N", client);
	
	
	if (db == null)
	{
		PrintToServer("Could not connect: %s", error);
		delete db;
	} 
	else 
	{
		//PrintToServer("[jailwarden][323]DB WORKING");//debug
		char steamid64[64];
		char steamid2[64];
		char ip[32];
		char username[35];
	   	GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	   	GetClientAuthId(client, AuthId_Steam2, steamid2, 64);
		GetClientIP(client, ip, 32, true);
		GetClientName(client, username, 35);
		
		char buffer[512];
		Format(buffer, 512, "SELECT `id` FROM `id` WHERE `steamid64` = '%s'", steamid64);
		//Format(buffer, 255, "SELECT * FROM `id`");
		DBResultSet query = SQL_Query(db, buffer);
		if (query == null)
	   	{
			PrintToServer("query = null, error: %s",buffer);
			delete query;
			delete db;
	   	}
		else
		{
			PrintToServer("[DB][344] query != null");
			if (SQL_GetRowCount(query) == 0)
			{
				Format(buffer, 512, "INSERT INTO `id` (`id`, `steamid`, `steamid64`, `reg_ip`, `last_ip`, `name`, `exp`, `credits`, `first_visit`, `last_visit`) VALUES (NULL, '%s', '%s', '%s', '%s', '%s', '0', '100', NOW(), NOW());", steamid2, steamid64, ip, ip, username);
				if (!SQL_FastQuery(db, buffer))
				{
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				if(Stats_CreateDb(client))
					LogMessage("База статистики для %N создана", client);
				else
					LogMessage("База статистики для %N не создана", client);
				LogMessage("[DB][Event_PlayerSpawn] Новый игрок %s занесен в базу данных", steamid64);
				LogMessage(buffer);	
				delete query;
				delete db;
			}
			else
			{
				Format(buffer, 512, "UPDATE `id` SET `last_IP` = '%s', `last_visit` = NOW() WHERE `id`.`steamid64` = %s;", ip, steamid64);
				//LogMessage("[DB][359]");
				//LogMessage(buffer);
				UpdateBanTime(client);
				if (!SQL_FastQuery(db, buffer))
				{
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				if(GetClientTeam(client) == CS_TEAM_CT)
				{
					if(IsCtBannedDb(client) == 1)
					{
						CGOPrintToChat(client, "У вас есть блокировка! Вы были переведены за Т");
						ChangeClientTeam(client, CS_TEAM_T);
						LogMessage("%N, id - %i, был переведен за Т блокировкой", client, GetId(client));
					}
				}
				if(!Stats_IsDbCreated(client))
					Stats_CreateDb(client);
			}
			delete query;
			delete db;
		}
	}
	

	
	CreateTimer(1.0, CheckPlayerNameTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		if(IsPlayerVip(client))
		{
			if(GetId(client) == 11 || GetId(client) == 2)
			{
				//CGOPrintToChatAll("ID 11");
				SetEntityModel(client, "models/player/custom_player/nf/batmanak/terr_f.mdl");
				//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
				//AcceptEntityInput(ent, "KillHierarchy");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2_arms.mdl");
			}
			else
			{
				//SetEntityModel(client, "models/player/custom/ekko/ekko.mdl");
				SetEntityModel(client, "models/player/custom_player/nf/batmanak/terr_f.mdl");
				//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
				//AcceptEntityInput(ent, "KillHierarchy");
				SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3_arms.mdl");
			}
			
		}
		else if(GetId(client) == 11 || GetId(client) == 2)
		{
			SetEntityModel(client, "models/player/custom_player/legacy/prisioner/prisioner.mdl");
			//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			//AcceptEntityInput(ent, "KillHierarchy");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2_arms.mdl");
		}
		else
		{
			SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2.mdl");
			//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			//AcceptEntityInput(ent, "KillHierarchy");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/prisoner2/prisoner2_arms.mdl");
		}
	}
	else if(GetClientTeam(client) == CS_TEAM_CT)
	{
		if(IsPlayerVip(client))
		{
			SetEntityModel(client, "models/player/custom_player/kuristaja/nanosuit/nanosuitv3.mdl");
			//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			//AcceptEntityInput(ent, "KillHierarchy");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/nanosuit/nanosuit_arms.mdl");
	
		}
		else
		{
			SetEntityModel(client, "models/player/custom_player/legacy/security/security.mdl");
			//int ent = 	GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
			//AcceptEntityInput(ent, "KillHierarchy");
			SetEntPropString(client, Prop_Send, "m_szArmsModel", "models/player/custom_player/kuristaja/jailbreak/guard3/guard3_arms.mdl");
		}
	}
	
	Vip_Event_PlayerSpawn(client);
	
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i))
		{
			g_playerStatus[i] = GetAdminPriority(GetAdminStatus(i));	
		}
	}
	

	/*
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		
		
		if(IsCtBanned(client, 3))
		{
			CGOPrintToChatAll("[jailwarden.375] Да, забанен");
			
			CGOPrintToChatAll("Поэтому пошел нахуй из СТ!");
			ChangeClientTeam(client, CS_TEAM_T);
		}
		else
		{
			CGOPrintToChatAll("[jailwarden.375] Нет, не забанен");
		}
		
		
	}
	*/
	
}





stock Action DebugAction_Save(int client, int args)
{
	//убрать дебаг позже
	
	static int sum;
	
	if(args != -1)
	{
		if(args > 0)
		{
			sum = sum + args;
		}
		else
		{
			CGOPrintToChat(client, "число должно быть больше 0!");
		}
	}
	else
	{
		CGOPrintToChat(client, "Счетчик равен: %d", sum);
		CGOPrintToChat(client, "Счетчик: ++++++");
		sum++;
		CGOPrintToChat(client, "Счетчик равен: %d", sum);
	}
	
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	
	
	//int client = GetClientOfUserId(event.GetInt("userid"));	
	
	
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int killed = GetClientOfUserId(event.GetInt("userid"));
	SetClientListeningFlags(killed, VOICE_NORMAL);
	LogMessage("%N(%i) был убит %N(%i)!", killed, GetId(killed), killer, GetId(killer));
	
	
	//Debug
	
	char k_name[32];
	GetClientName(killed, k_name, 32);
	/*
	
	CGOPrintToChatAll("killer - %i, killed - %i", killer, killed);
	CGOPrintToChatAll("killer - %N, killed - %s",killer, k_name);
	char w_name[32];
	GetClientName(wardenid, w_name, 32);
	CGOPrintToChatAll("wardenid = %i, name - %s", wardenid, w_name);
	*/
	
	
	if (killer != 0 && killer != killed && IsClientInGame(killed) && IsClientInGame(killer))
	{
		if (GetClientTeam(killer) == CS_TEAM_T && GetClientTeam(killed) == CS_TEAM_CT)
		{			
			AddXp(killer, 1);							
		}
		else if (GetClientTeam(killer) == CS_TEAM_CT && IsClientRebel(killed))
		{
			AddXp(killer, 1);
		}
	}
	
	
	if(killed == wardenid)
	{
		CGOPrintToChatAll("{RED}Командир %s потерял контроль над ситуацией", k_name);
		LogMessage("Командир %N (%i) умер", killed, GetId(killed));
		wardenid = 0;
		wardentaked = false;
		//CGOPrintToChatAll("wardenid = %i", wardenid);
		//CGOPrintToChatAll("Это %N", wardenid);
		UnmuteAllCt();
	}
}


/*
int WardenMenuHandle(Menu SwitchSideMenu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_Display:
		{
            char szTitle[128];
            FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            (view_as<Panel>(args)).SetTitle(szTitle); // iItem имеет тип int, его нужно привести к типу Panel и использовать метод SetTitle для установки заглавия.
        }
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(args, info, sizeof(info);
			
			if(StrEqual(info, "item1"))
			{
				char a;
			}
			else if(StrEqual(info, "item1"))
			{
				char b;
			}
			else if(StrEqual(info, "item1"))
			{
				char c;
			}
			else if(StrEqual(info, "item1"))
			{
				char d;
			}
			
		}
		
	}
	
}
*/



int WardenMenu(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			//char szInfo[64], szTitle[128];
            //menu.GetItem(arg2, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
            //CGOPrintToChat(client, "Вы выбрали пункт: %i (%s, инфо: %s)", arg2, szTitle, szInfo);
			if(arg2 == 0)
			{
				Warden_Freeday(client);
				//delete menu;
			}
			if(arg2 == 1)
			{
				Warden_Mute();
				//delete menu;
			}
			if(arg2 == 2)
			{
				Warden_SlapCt(client);
				//delete menu;
			}
			if(arg2 == 3)
			{
				Warden_Noblock();
				//delete menu;
			}
		}
		case MenuAction_End:
		{
			//CGOPrintToChatAll("Menu End");
			delete menu;
		}
		case MenuAction_Cancel:
		{
			//Action
		}
	}
}



public Action OpenWardenMenu(int client)
{
	Menu menu = new Menu(WardenMenu, MenuAction_Select|MenuAction_End|MenuAction_Cancel);
	menu.SetTitle("Меню командира");
	menu.AddItem("1", "Дать фридей в следующем раунде");
	menu.AddItem("2", "Вкл/Выкл микрофоны СТ");
	menu.AddItem("3", "Дать подзатыльник");
	menu.AddItem("4", "Управление noblock");
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	//CGOPrintToChat(client, "{PURPLE}Типа открылась менюшка");
	return Plugin_Handled;
	
}




stock Action SendPrivateMessage(int client, int args)
{
	
	if(args <1)
	{
		ReplyToCommand(client, "[PM] Использование: sm_pm <userid|name> [message]");
		return Plugin_Handled;
	}
	char Arguments[256];
	GetCmdArgString(Arguments, sizeof(Arguments));
	
	
	char arg[65];
	int len = BreakString(Arguments, arg, sizeof(arg));
	
	if(len == -1)
	{
		len = 0;
		Arguments[0] = '\0';
	}
	return Plugin_Handled;
}


stock Action GetServerPlayerIds(int client, int args)
{
	//CGOPrintToChat(client, "[{BLUE}PM{DEFAULT}] Результат выведен в консоль");
	
	
	CGOPrintToChat(client,("[{BLUE}PM{DEFAULT}] Списов userid игроков на сервере:"));
	
	
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_SPECTATOR))
		{
			char name[32];
			GetClientName(i, name, 32);
			CGOPrintToChat(client, "[{BLUE}PM{DEFAULT}] Игрок %s имеет id %i ",name, GetClientUserId(i) );
		}	
	}
}


public Action GetMyId(int client, int args)
{
	char buffer[255];
	Format(buffer, 255, "{GREEN}[!id]{DEFAULT} Ваш ID: %d", GetId(client));
	CGOPrintToChat(client, buffer);
	LogMessage("%N(%i) посмотрел свой ID!", client, GetId(client));
	return Plugin_Handled;
}


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
			int temp_int;
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
					temp_int = SQL_FetchInt(query, 0);
					delete db;
					delete query;
					return temp_int;
				}
			}
		}
		return -1;
	}
	delete db;
	return -1;
}



Action UnmuteAll(Handle timer)
{
		//CGOPrintToChatAll("калбек");
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				if(!g_playerMutedByAdm[i])
				{
					//CGOPrintToChatAll("%N размутился", i);
					SetClientListeningFlags(i, VOICE_NORMAL);
				}					
			}
		}
		//CGOPrintToChatAll("Jailbreak: {GREEN}Микрофоны заключенных включены");
		if (g_TimerOne != null)
		{
			KillTimer(g_TimerOne);
			g_TimerOne = null;
			CGOPrintToChatAll("Jailbreak: {GREEN}Микрофоны заключенных включены");
		}	
}


int PlayersIds(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
            char szTitle[128];
            FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
            (view_as<Panel>(param2)).SetTitle(szTitle); 
        }
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char name[32];
			GetClientName(cid, name, 32);
			
			char buffer[255];
			if(GetId(cid) == 7)
			{
				Format(buffer, 255, "{GREEN}[!id]{DEFAULT} %s | Номер 007 | Ранг %d | %s",
					name, CalcRank(GetXP(cid)), GetAdminStatus(cid));
			}
			else
			{
				Format(buffer, 255, "{GREEN}[!id]{DEFAULT} %s | Номер %d | Ранг %d | %s",
					name, GetId(cid), CalcRank(GetXP(cid)), GetAdminStatus(cid));
			}
			CGOPrintToChatAll(buffer);
			LogMessage(buffer);
		}
	}
}



public Action GetUserIds(int client, int args)
{

	Menu menu = new Menu(PlayersIds);
	menu.SetTitle("Выберите игрока:");
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_SPECTATOR)
			{
				char name[32];
				GetClientName(i, name, 32);
			
				char cid[8];
				IntToString(i, cid, 8);
				menu.AddItem(cid, name);
			}
		}
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;

}

public void AddXp(int client, int amount)
{
	int oldXp = GetXP(client);
	SetXp(client, oldXp + amount);
	int oldRank = CalcRank(oldXp);
	int newRank = CalcRank(oldXp + amount);
	char name[35];
	GetClientName(client, name, 35);
	if (newRank > oldRank)
	{
		CGOPrintToChatAll("{GREEN}[!id]{DEFAULT} {OLIVE}Игрок %s получил новый ранг!", name);
		LogMessage("Игрок %s(%i) получил новый ранг - %i", client, GetId(client), newRank);
	}
}

int GetXP(int client)
{
	if (client == -1)
	{
		return 0;
	}
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect: %s", error);
	}
	else 
	{		
		char steamid64[64];
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
		char buffer[255];
		Format(buffer, 255, "SELECT `exp` FROM `id` WHERE `steamid64` = '%s'", steamid64);
		DBResultSet query = SQL_Query(db, buffer);
		
		if (query == null)
		{
			PrintToServer("SQL Query errored (GetXP(%d))", client);
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


void SetXp(int client, int xp)
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect: %s", error);
	}
	else
	{
		char steamid64[64];
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		
		char buffer[255];
		Format(buffer, 255, "UPDATE `id` SET `exp` = '%d' WHERE `id`.`id` = %d ", xp, GetId(client));
		if (!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		
		delete db;
	}
}


int CalcRank(int exp)
{
	if (exp < 30)
	{
		return 1;
	}
	else if (exp >= 30 && exp < 90)
	{
		return 2;
	}
	else if (exp >= 90 && exp < 180)
	{
		return 3;
	}
	else if (exp >= 180 && exp < 450)
	{
		return 4;
	}
	else if (exp >= 450 && exp < 600)
	{
		return 5;
	}
	else if (exp >= 600 && exp < 1500)
	{
		return 6;
	}
	else if (exp >= 1500 && exp < 6700)
	{
		return 7;
	}
	else if (exp >= 6700 && exp < 11000)
	{
		return 8;
	}
	else if (exp >= 11000 && exp < 34000)
	{
		return 9;
	}
	else if (exp >= 34000 && exp < 89000)
	{
		return 10;
	}
	else if(exp >= 89000)
	{
		return 11;
	}
	
	return 1;
}

/*
int CTPrivilegy_Menu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
            FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
            (view_as<Panel>(param2)).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char name[32];
			GetClientName(param1, name, 32);
			
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			int cid = -1;
			StringToIntEx(info, cid);
			char targetname[32];
			GetClientName(cid, targetname,32);
			ChangeClientTeam(cid, CS_TEAM_T);
			CGOPrintToChatAll("%s перевел игрока %s за терроистов.",name,targetname);
			
		}
		
	}

	
}

*/
/*
public Action CTPrivilegy(int client, int args)
{

	char name[32];
	GetClientName(client, name, 32);
	CGOPrintToChat(client, "CTPrivilegy plugin");
	
	Menu menu = new Menu(CTPrivilegy_Menu);
	menu.SetTitle("Перевести за террористов");
	for (int i = 1; i <= MaxClients; i++) 
	{			
		if (IsClientInGame(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				
				char targetname[32];
				GetClientName(i, targetname, 32);
				if(StrEqual(name, targetname))
				{
					//
				}
				else
				{
					char cid[8];
					IntToString(i, cid, 8);
					menu.AddItem(cid, targetname);
				}
			}
		}
	}
	menu.Display(client,MENU_TIME_FOREVER);
	return Plugin_Handled;

}
*/

char[] GetAdminStatus(int client)
{
	
	if (client == -1)
	{
		char res[64] = "Говнокод";
		return res;
	}
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	
	if (db == null)
	{
		PrintToServer("GetAdminStatus SQL ERROR");
	}
	else
	{
		
		char buffer[255];
		Format(buffer, 255, "SELECT `lvl` FROM `admin_lvl` WHERE `id` = '%i';", GetId(client));
		DBResultSet query = SQL_Query(db, buffer);
		if (query == null)
		{
			PrintToServer("SQL Query errored (GetAdminStatus())");
		}
		else
		{
			if (SQL_GetRowCount(query) == 0)
			{
				char res[64] = "Игрок без привилегий";
				return res;
			}
			else
			{
				char roleName[64];
				while (SQL_FetchRow(query))
				{
					SQL_FetchString(query, 0, roleName, 64);
				}
				
				if (StrEqual(roleName, "sadmin"))
				{
					char res[64] = "Супер-администратор";
					return res;
				}
				else if (StrEqual(roleName, "gladmin"))
				{
					char res[64] = "Главный администратор";
					return res;
				}
				else if (StrEqual(roleName, "admin"))
				{
					char res[64] =  "Администратор";
					return res;
				}
				else if (StrEqual(roleName, "CT"))
				{
					char res[64] = "Привилегия СТ";
					return res;
				}
				else
				{
					char res[64] =  "Игрок без привилегий";
					return res;
				}
			}
		}
	}
}



int GetAdminPriority(char[] rank)
{
	if (StrEqual(rank, "Супер-администратор"))
	{
		return 4; //old - 5
	}
	else if (StrEqual(rank, "Главный администратор"))
	{
		return 3; //old - 4
	}
	else if (StrEqual(rank, "Администратор"))
	{
		return 2; //old - 3
	}
	else if (StrEqual(rank, "Привилегия СТ"))
	{
		return 1; //old - 2
	}
	else if (StrEqual(rank, "Говнокод"))
	{
		return 1000;
	}
	else
	{
		return 0; //old - 1
	}
}



//!setct выдача Кт привы
public Action SetCTCmd(int client, int args)
{
	AdmSetCt(client);
}


//!setct меню для выдачи кт привы
int SetCtH(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
			(view_as<Panel>(param2)).SetTitle(szTitle); 
		}		
		case MenuAction_Select:
		{
			char error[255]
			Database db = SQL_DefConnect(error, sizeof(error));
			
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char s_name[32];
			GetClientName(cid, s_name, 32);
			char f_name[32];
			GetClientName(param1, f_name, 32);
			
			char steamid2[64];
			GetClientAuthId(cid, AuthId_Steam2, steamid2, 64);
			
			char buffer[255];
			Format(buffer, 255, "INSERT INTO `admin_lvl` (`counter`, `id`, `name`, `steamid`, `recieved`, `last_visit`, `ingame_time`, `setter`, `lvl`, `set_date`) VALUES (NULL, '%d', '%s', '%s', NOW(),NOW() , 0, '%s', 'CT', NOW());", GetId(cid), s_name, steamid2, f_name);
			LogMessage(buffer);
			if (!SQL_FastQuery(db, buffer))
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("SETCT: Failed to query (error: %s)", error);
			}
			
			//Action_CtPrivilegyManager(cid); //раньше она добавляла в админфайл флаг
			CGOPrintToChatAll("{GREEN}[!ct] {DEFAULT}Игрок %s выдал привилегию игроку %s",f_name, s_name );
			LogMessage("Администратор %s выдал привиоегию СТ игроку %s", f_name, s_name);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action AdmSetCt(int client)
{
	CGOPrintToChatAll("Инициализировано меню выдачи СТ");
	Menu menu = new Menu(SetCtH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Выберите игрока:");
	//PrintToServer("920");
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_SPECTATOR)
			{
				if(StrEqual(GetAdminStatus(i), "Игрок без привилегий"))
				{
					//PrintToServer("929");
					char name[32];
					GetClientName(i, name, 32);
			
					char cid[8];
					IntToString(i, cid, 8);
					menu.AddItem(cid, name);
				}
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
	
}




//!addadmin выдача админки по нику/userid (не используется)
public Action Command_AddAdmin(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addadmin <name or #userid> <flags> <password>");
		return Plugin_Handled;
	}

	new String:szTarget[64], String:szFlags[20], String:szPassword[32];
	GetCmdArg(1, szTarget, sizeof(szTarget));
	GetCmdArg(2, szFlags, sizeof(szFlags));
	GetCmdArg(3, szPassword, sizeof(szPassword));

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" \"%s\"", szTarget, szFlags, szPassword);

	CloseHandle(hFile);

	return Plugin_Handled;
}


stock Action Action_CtPrivilegyManager(int client)
{
	
	
	
	/* //Добавление СТ привилегии в admins_simple по стимайди и флагу 'o'
	new String:steamid2[64], String:flag[20] = "p", String:name[32];
	//GetCmdArg(1, szTarget, sizeof(szTarget));
	//GetCmdArg(2, szFlags, sizeof(szFlags));
	
	//char steamid2[64];
	 //flag[20] = "o";
	//char name[64];
	
	GetClientName(client, name, 32);
	GetClientAuthId(client, AuthId_Steam2, steamid2, 64);

	new String:szFile[256];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/admins_simple.ini");

	new Handle:hFile = OpenFile(szFile, "at");

	WriteFileLine(hFile, "\"%s\" \"%s\" //\%s | ID: %d", steamid2, flag, name, GetId(client));

	CloseHandle(hFile);
	*/

	return Plugin_Handled;
}



//ADMIN MENU CUSTOM FUNCTIONS
/*
public Action Adm_AfkKick(int client, int args)
{
	if(!IsClientValid(client) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	if(args != 1)
	{
		ReplyToCommand(client, "Хуйня не работает");
		CGOPrintToChatAll("{RED}1036-37 не работает");
		return Plugin_Handled;
	}
		new String: target_name[MAX_TARGET_LENGTH],
		String: buffer[64],
		target_list[MAXPLAYERS],
		bool: tn_is_ml,
		target_count;
	
	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrEqual(buffer, "@spec", false) || StrEqual(buffer, "@spectator", false))
	{
		ReplyToCommand(client, "%t", "CMD_OnlyInTeam");
		return Plugin_Handled;
	}
	
	if((target_count = ProcessTargetString(buffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for(new i = 0; i < target_count; i++)
	{
		if(IsClientInGame(target_list[i]))
		{
			if(GetClientTeam(target_list[i]) >= 2)
			{
				//CS_RespawnPlayer(target_list[i]);
				ChangeClientTeam(target_list[i], CS_TEAM_SPECTATOR);
			}
			else if(!tn_is_ml)
			{
				ReplyToCommand(client, "%t", "CMD_OnlyInTeam");
				return Plugin_Handled;
			}
		}
	}
	
	if(tn_is_ml)
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Respawn", target_name);
		LogActionEx(client, "%t", "CMD_Respawn", target_name);
	}
	else
	{
		ShowActivity2(client, CMD_PREFIX, "%t", "CMD_Respawn", "_s", target_name);
		LogActionEx(client, "%t", "CMD_Respawn", "_s", target_name);
	}
	return Plugin_Handled;
}

*/
bool IsClientValid(int client)
{
	return ((client > 0) && (client <= MaxClients) && IsClientInGame(client));
}



//Для Adm_AfkKick сурсовский логгер



/*

public void OnMapEnd()
{
	
	
}
*/
//Написать на OnPlayerDisconnect и OnPlayerDeath функцию отмены командира и обнуления wardenid


/*
public Action Adm_Ct(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	hCtMenu.Display(client, TopMenuPosition_Start);
	return Plugin_Handled;
	
}
*/


public Action AdmCt_Gates(int client, int args)
{
	//CGOPrintToChatAll("Двери перед иф");
	if(g_playerStatus[client] >= 1)
	{
		//CGOPrintToChatAll("Иф");
		AdmCt(client);
	}
}


int AdmCt_menu(Menu menuu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(arg2).SetTitle(szTitle); 
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
			CreateBanDb(cid, client, 1);
			
			
			
			//g_TimerCtBan = CreateTimer(5.0, CtBan, cid); //Таймер отключен, тк эта хуйня
			//работает не так, как нужно
			
			CGOPrintToChatAll("{DEFAULT}[!ct]{DEFAULT} %s перевел игрока {RED}%s", f_name, name);
			LogMessage("%N(%i) перевел игрока %N(%i) за Т", client, GetId(client), cid, GetId(cid));
		}
	}
}



public Action AdmCt(int client)
{
	Menu menuu = new Menu(AdmCt_menu);
	menuu.SetTitle("Заблокировать за СТ");
	//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1191");//debug
	char f_name[32];
	GetClientName(client, f_name, 32);
	
	
	
	
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientValid(i))
		{
			//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1203");//debug
			if(GetClientTeam(i) == CS_TEAM_CT)
			{			
				if(client != i) //FIXed!!! отображать себя - i+1000
				{	
					if(StrEqual(GetAdminStatus(i), "Игрок без привилегий")) //проверка адм уровня
					{
						char name[32];
						GetClientName(i, name, 32);
						char cid[8];
						IntToString(i, cid, 8);
						menuu.AddItem(cid, name);
							
					}
				}
			}
		}
	}
	menuu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;	
}


int Adm_AfkKickMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(arg2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			CGOPrintToChatAll("I - %i, %N", cid, cid);
			
			if(IsClientValid(cid) && IsPlayerAlive(cid) && (GetClientTeam(cid) == CS_TEAM_CT || GetClientTeam(cid) == CS_TEAM_T))
			{
				ChangeClientTeam(cid, CS_TEAM_SPECTATOR);
				CGOPrintToChatAll("[!admin] %N перевел {RED}%N {DEFAULT}за наблюдателей", client, cid);
				LogMessage("%N(%i) перевел %N(%i) за наблюдателей", client, GetId(client), cid, GetId(cid));
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}




public Action Adm_AfkKick(int client, int args) //Для теста
{
	Adm_AfkKick1(client);
}

public Action Adm_AfkKick1(int client)
{
	
	Menu menu = new Menu (Adm_AfkKickMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Перевести AFK");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT) && client != i) //BUGDEBUG 
		{
			char cid[8];
			char name[32];
			IntToString(i, cid, 8);
			GetClientName(i, name, 32);
			
			menu.AddItem(cid, name);
		}
	}
	
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}


//Вызывается из [DB] на Event_PlayerSpawn
public Action CreateBanDb(int client, int args1, int args2)
{
	//client - клиент, которого банят
	//args1 - клиент, который забанил(админ)
	//args2 - тип бана, 0 - фулл разбан, 1 - CT BAN, 2 - АдминКтБан(30мин), 3 - Мут 15 минут (адм), 
	//
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	if(db == null)
	{
		PrintToServer("CreateBanDb not connect: %s", error);
	}
	else
	{
		char steamid64[64];
		char name[64];
		
		char admin_name[64];
		GetClientName(args1, admin_name, sizeof(admin_name));
		FormatEx(admin_name, sizeof(admin_name), "%s[%i]", admin_name, GetId(args1));
	
		GetClientName(client, name, 32);
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		
		char buffer[512];
		if(args2 == 1)
		{
			Format(buffer, sizeof(buffer), "SELECT `ban_type` FROM `bans` WHERE `steamid64` = '%s'", steamid64);
		}
		else if(args2 == 2)
		{
			Format(buffer, sizeof(buffer), "SELECT `ban_type` FROM `bans` WHERE `steamid64` = '%s'", steamid64);
		}
		else if(args2 == 3)
		{
			Format(buffer, sizeof(buffer), "SELECT `ban_type` FROM `bans` WHERE `steamid64` = '%s'", steamid64);
		}
		LogMessage(buffer);
		
		DBResultSet query = SQL_Query(db, buffer);
		if(query == null)	
		{
			PrintToServer("[CreateBanDb]query = null, error: %s",buffer);
		}
		else
		{
			PrintToServer("[CreateBanDb][1393] query != null");
			if(SQL_GetRowCount(query) == 0)
			{
				if(args2 == 1)
				{					//Перевод за Т (!ct) на 15 минут
					char date_buffer[40];
					Format(date_buffer, sizeof(date_buffer), "DATE_ADD(NOW(),INTERVAL 15 MINUTE)");
					Format(buffer, sizeof(buffer), "INSERT INTO `bans` (`counter`, `id`, `steamid64`, `name`, `admin`, `bantime`, `status`, `ban_type`, `ban_time1`, `ban_time2`) VALUES (NULL, '%d', '%s', '%s', '%s', '15', '1', '1', NOW(), %s)",
					GetId(client), steamid64, name, admin_name, date_buffer);
				}
				else if(args2 == 2)
				{					//Перевод за Т (!admin) на 30 минут
					char date_buffer[40];
					Format(date_buffer, sizeof(date_buffer), "DATE_ADD(NOW(),INTERVAL 30 MINUTE)");
					Format(buffer, sizeof(buffer), "INSERT INTO `bans` (`counter`, `id`, `steamid64`, `name`, `admin`, `bantime`, `status`, `ban_type`, `ban_time1`, `ban_time2`) VALUES (NULL, '%d', '%s', '%s', '%s', '30', '1', '2', NOW(), %s)",
					GetId(client), steamid64, name, admin_name, date_buffer);
				}
				else if(args2 == 3)
				{ 					//Мут (!admin) на 15 минут
					char date_buffer[40];
					Format(date_buffer, sizeof(date_buffer), "DATE_ADD(NOW(),INTERVAL 15 MINUTE)");
					Format(buffer, sizeof(buffer), "INSERT INTO `bans` (`counter`, `id`, `steamid64`, `name`, `admin`, `bantime`, `status`, `ban_type`, `ban_time1`, `ban_time2`) VALUES (NULL, '%d', '%s', '%s', '%s', '15', '1', '3', NOW(), %s)",
					GetId(client), steamid64, name, admin_name, date_buffer);
					g_playerMutedByAdm[client] = true;
				}
				if (!SQL_FastQuery(db, buffer))
				{
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				LogMessage(buffer);
				LogMessage("[CreateBanDb][1411]");
				
			}
			else if(SQL_GetRowCount(query) == 1 && args2 == 2)
			{
				DelBanDb(client);
				CreateBanDb(client, args1, 2);
			}
			else if(SQL_GetRowCount(query) == 1 && args2 == 3)
			{
				DelBanDb(client);
				CreateBanDb(client, args1, 3);
			}
			else if(SQL_GetRowCount(query) == 2 && args2 == 3)
			{
				DelBanDb(client);
				CreateBanDb(client, args1, 3);
			}
		}
	}
}
//Добавить сравнение времени на сервере и времени до конца бана
public Action IsCtBannedDb(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	if(db == null)
	{
		PrintToServer("IsCtBannedDb not connect: %s", error);
	}
	else
	{

		char name[64];
		char steamid64[64];
		
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		GetClientName(client, name, 32);
		//id = GetId(client);
		
		
		char buffer[255];
		Format(buffer, 255, "SELECT `ban_type` FROM `bans` WHERE `steamid64` = '%s'", steamid64);
		DBResultSet query = SQL_Query(db, buffer);
		if(query == null)
		{
			PrintToServer("[CreateBanDb]query = null, error: %s",buffer);
		}
		else
		{

			PrintToServer("[CreateBanDb][1393] query != null");
			if(SQL_GetRowCount(query) == 0)
			{
				//LogMessage("BAN CHECKING: Player '%s' HAS 0 BANS", name);
				return 0;
			}
			else
			{
				//Проверка на тип бана 
				if(SQL_GetRowCount(query) == 1)
				{
					if(DelBanIfEnded(client) == 1)
					{
						return 0;
					}
					else 
					{
						//LogMessage("BAN CHECKING: Player '%s' HAS BAN", name);
						return 1;
					}
				}
				if(SQL_GetRowCount(query) == 2)
				{
					if(DelBanIfEnded(client) == 1)
					{
						return 0;
					}
					else 
					{
						//LogMessage("BAN CHECKING: Player '%s' HAS BAN", name);
						return 2;
					}
				}
				if(SQL_GetRowCount(query) == 3)
				{
					if(DelBanIfEnded(client) == 1)
					{
						return 0;
					}
					else 
					{
						//LogMessage("BAN CHECKING: Player '%s' HAS BAN", name);
						return 3;
					}
				}
				/*
				LogMessage("BAN CHECKING: Player '%s' HAS BAN", name);
				if(SQL_GetRowCount(query) == 1)
				{
					LogMessage("1");
					return 1;
				}
				*/
				
			}
		}
	}
}

public Action UpdateBanTime(int client)
{
	if(IsCtBannedDb(client) == 1)
	{
		char error[255];
		Database db = SQL_DefConnect(error,sizeof(error));
		char steamid64[64];
		char name[64];
	
		GetClientName(client, name, 64);
		GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
		//Format(buffer, 255, "SELECT `counter` FROM `bans` WHERE `steamid64` = '%s' AND `ban_time1` >= `ban_time2`");
	
		char buffer[255];
		Format(buffer, 255, "SELECT `counter` FROM `bans` WHERE `steamid64` = '%s'", steamid64);
		DBResultSet query = SQL_Query(db, buffer);
		if(query == null)
		{
			PrintToServer("[UpdateBanTime]query = null, error: %s",buffer);
			return Plugin_Handled;
		}
		else
		{
			PrintToServer("[UpdateBanTime][1498] query != null");
			if(SQL_GetRowCount(query) == 0)
			{
				LogMessage("У игрока %s нет блокировок", name);
				return Plugin_Handled;
			}
			else
			{
			LogMessage("У игрока %s найдены блокировки! Время обновлено", name);
			UpdBanTime(client);
			return Plugin_Handled;
			}
		}
	}
	else
	{
		return Plugin_Handled;
	}
}

public Action UpdBanTime(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	char steamid64[64];
	char name[64];
	
	GetClientName(client, name, 64);
	GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
	char buffer[255];
	Format(buffer, 255, "UPDATE `bans` SET `ban_time1` = NOW() WHERE `steamid64` = '%s'", steamid64);
	//DBResultSet query = SQL_Query(db, buffer);
	if (!SQL_FastQuery(db, buffer))
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
	LogMessage(buffer);
	LogMessage("[UpdBanTime][1533] Игроку %s обновлено время в таблице банов", name);
	
}


public Action DelBanIfEnded(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	char steamid64[64];
	char name[64];
	
	GetClientName(client, name, 64);
	GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
	char buffer[255];
	Format(buffer, 255, "SELECT `counter` FROM `bans` WHERE `steamid64` = '%s' AND `ban_time1` >= `ban_time2`", steamid64);
	DBResultSet query = SQL_Query(db, buffer);
	if(query == null)
	{
		PrintToServer("[DelBanIfEnded]query = null, error: %s",buffer);
		return Plugin_Handled;
	}
	else
	{
		PrintToServer("[DelBanIfEnded][1572] query != null");
		if(SQL_GetRowCount(query) == 0)
		{
			LogMessage("[DelBanIfEnded]У игрока %s остается активная блокировка", name);
			return 0;
		}
		else
		{
			LogMessage("[DelBanIfEnded]У игрока %s закончилось время блокировки!", name);
			DelBanDb(client);
			return 1;
		}
	}
	//LogMessage(buffer);
	//LogMessage("[DelBanIfEnded][1584] Игроку %s инициализирован DelBanDb()", name);
}

public Action DelBanDb(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error,sizeof(error));
	
	char steamid64[64];
	char name[64];
	
	GetClientName(client, name, 64);
	GetClientAuthId(client, AuthId_SteamID64, steamid64, 64);
	
	char buffer[255];
	Format(buffer, 255, "DELETE FROM `bans` WHERE `steamid64` = '%s'", steamid64);
	//DBResultSet query = SQL_Query(db, buffer);
	if (!SQL_FastQuery(db, buffer))
	{
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	}
	g_playerMutedByAdm[client] = false;
	LogMessage(buffer);
	LogMessage("[DelBanDb][1607] Игрок %s успешно удален из таблицы банов", name);
	delete db;
}


public Action SetTestSkin(int client, int args)
{
	//SetEntityModel(client, "models/player/custom_player/kodua/pudge/pudge.mdl");
}



// Warden Menu Actions:

int Warden_Freeday_Menu(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			//CGOPrintToChatAll("1683");
			char info[32];
			menu.GetItem(arg2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char name[32];
			GetClientName(cid, name, 32);
			
			char f_name[32];
			GetClientName(client, f_name, 32);
			
			CGOPrintToChatAll("[!w] {LIME}%s получит фридей в следующем раунде",name);
			WardenGivesFd(cid);
		}
	}
}

public Action Warden_Freeday(int client)
{
	Menu menu = new Menu(Warden_Freeday_Menu)
	menu.SetTitle("Выдать фридей на следующий раунд");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i))
		{
			if(GetClientTeam(i) == CS_TEAM_T)
			{
				char name[32];
				GetClientName(i, name, 32);
				char cid[8];
				IntToString(i, cid, 8);
				menu.AddItem(cid, name);
			}	
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action WardenGivesFd(int client)
{
	//LogMessage("Перед двумя форами");
	for(int i = 0; i < sizeof(g_fdids); i++)
	{
		//LogMessage("Первый фор");
		if(g_fdids[i] == client)
		{
			//LogMessage("Внутри условия 1 фора");
			return Plugin_Handled;
		}
	}
	for(int i = 0; i < sizeof(g_fdids); i++)
	{
		//LogMessage("Второй фор");
		if(g_fdids[i] == 0)
		{
			//LogMessage("Внутри условия 2 фора");
			g_fdids[i] = client;
			return Plugin_Handled;
		}
	}
}


public void CheckPlayerToFd()
{
	/*
	for(int i = 1; i < MaxClients; i++)
	{
		if(GetClientTeam(i) == CS_TEAM_T)
		{
			for(int j = 0; j < sizeof(g_fdids)	; j++)
			{
				if(i == g_fdids[j])
				{
					SetEntityRenderColor(i,9,255,9,255);
				}
				g_fdids[j] = 0;
			}
		}
	}
	*/
	//CGOPrintToChatAll("FUNC");
	for(int i = 0; i < sizeof(g_fdids); i++)
	{
		if(IsClientValid(g_fdids[i]) && IsClientInGame(g_fdids[i]) && GetClientTeam(g_fdids[i]) == CS_TEAM_T)
		{
			SetEntityRenderColor(g_fdids[i], 9, 255, 9, 255);
		}
		g_fdids[i] = 0;
	}
}


public void Warden_Mute()
{
	if(g_isctmutted)
	{
		g_isctmutted = !g_isctmutted;
		CGOPrintToChatAll("[!w] Командир {GREEN}включил {DEFAULT}микрофон СТ");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && GetId(i) != 1 && GetId(i) != 17  && i != wardenid)
			{
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
	else
	{
		g_isctmutted = !g_isctmutted;
		CGOPrintToChatAll("[!w] Командир {RED}отключил{DEFAULT} микрофон СТ");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && GetId(i) != 1 && GetId(i) != 17  && i != wardenid)
			{
				SetClientListeningFlags(i, VOICE_MUTED);
			}
		}
	}
	
	
	
	
	/*for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			if(GetId(i) == 1 || GetId(i) == 17 || i == wardenid) // ???
			{
				
			}
			else
			{
				if(g_isctmutted)
				{
					g_isctmutted = !g_isctmutted;
					SetClientListeningFlags(i, VOICE_NORMAL);
				}
				else
				{
					g_isctmutted = !g_isctmutted;
					SetClientListeningFlags(i, VOICE_MUTED);
				}
			}
		}
	}
	if(g_isctmutted)
	{
		CGOPrintToChatAll("[!w] Командир {RED}отключил{DEFAULT} микрофон СТ");
	}
	else
	{
		CGOPrintToChatAll("[!w] Командир {GREEN}включил {DEFAULT}микрофон СТ");
	}
	*/
}


public void UnmuteAllCt()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
		{
			if(!g_playerMutedByAdm[i])
			{
				//CGOPrintToChatAll("%N CT размутился", i);
				SetClientListeningFlags(i, VOICE_NORMAL);
			}
		}
	}
	g_isctmutted = false;
}


int Warden_SlapCt_Menu(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			//CGOPrintToChatAll("123213131");
			char info[32];
			menu.GetItem(arg2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char name[32];
			GetClientName(cid, name, 32);
			
			char f_name[32];
			GetClientName(client, f_name, 32);
			
			if(IsClientValid(cid) && IsPlayerAlive(cid))
			{
				ChangeClientTeam(cid, CS_TEAM_T);
				CS_RespawnPlayer(cid);
			}
			else if(IsClientValid(cid))
			{
				CS_RespawnPlayer(cid);
			}
			
			
			CGOPrintToChatAll("[!w] Командир %s дал подзатыльник %s", f_name, name);
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Warden_SlapCt(int client)
{
	
	
	Menu menu = new Menu(Warden_SlapCt_Menu, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Дать подзатыльник");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
		{
			
			//CGOPrintToChatAll("ВАЛИД");
			if(GetId(i) == 1 || i == wardenid)
			{
				//CGOPrintToChatAll("ИФ");
			}
			else
			{
				char name[32];
				GetClientName(i, name, 32);
				char cid[8];
				IntToString(i, cid, 8);
				menu.AddItem(cid, name);
				//CGOPrintToChatAll("ЭЛС");
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public void Warden_Noblock()
{
	g_wardennoblock = !g_wardennoblock;
	Cvar_SolidTeamMates.SetBool(!g_wardennoblock, true, false);
	CGOPrintToChatAll("[!w]: Noblock %s", (g_wardennoblock) ? "{GREEN}включен" : "{RED}выключен");
}



public Action Warden_Noblock_User(int client, int args) //Чисто для теста !noblock в regcmd
{
	Warden_Noblock();
}

// ADMIN MENU CUSTOM:


int CustomAdminMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
            menu.GetItem(arg2, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
            //CGOPrintToChat(client, "Вы выбрали пункт: %i (%s, инфо: %s)", arg2, szTitle, szInfo);
			int number;
			StringToIntEx(szInfo, number);
			//CGOPrintToChatAll("I = %i",number);
			
			switch(number)
			{
				case 1:
				{
					Adm_AfkKick1(client); //Игрок AFK

				}
				case 2:
				{
					Adm_UnblockUser(client); //Разблокировать игрока

				}
				case 3:
				{
					//CreateBeacon(client); //Установить маяк на игрока

				}
				case 4:
				{
					Adm_CustomMute(client);//Отключить микрофон и чат
				}
				case 5:
				{
					Adm_CtBan(client);
					//Перевести за террористов
				}
				case 6:
				{
					Adm_SetName(client);//Изменить имя игрока
				}
				case 7:
				{
					Adm_ChangeMap(client);//Сменить карту
				}
				//Главный администратор и выше
				case 8: 
				{
					AdmSetCt(client); //Выдать СТ привилегию
				}
				case 9:
				{
					AdmDelCt(client);//Снять СТ привилегию
				}
				case 10:
				{
					AdmKickPlayer(client);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action CustomAdmin(int client, int args)
{
	if(IsClientValid(client) && IsClientInGame(client) && client > 0)
	{
		if(g_playerStatus[client] > 1)
		{
			char buffer[64];
			Menu menu = new Menu(CustomAdminMenuH, MenuAction_Select|MenuAction_End);
			menu.SetTitle("Меню администратора");
			
			switch(g_playerStatus[client])
			{
				case 2: //Администратор
				{
					menu.AddItem("1", "Игрок AFK");
					menu.AddItem("2", "Разблокировать игрока");
					menu.AddItem("3", "Установить на игрока маяк");
					menu.AddItem("4", "Отключить микрофон и чат");
					menu.AddItem("5", "Перевести за террористов");
					menu.AddItem("6", "Изменить имя игрока");
					menu.AddItem("7", "Сменить карту");
					
				}
				case 3, 4: //Главный администратор и Супер-администратор
				{
					menu.AddItem("1", "Игрок AFK");
					menu.AddItem("2", "Разблокировать игрока");
					menu.AddItem("3", "Установить на игрока маяк");
					menu.AddItem("4", "Отключить микрофон и чат");
					menu.AddItem("5", "Перевести за террористов");
					menu.AddItem("8", "Выдать привилегию СТ");
					menu.AddItem("9", "Снять СТ привилегию");
					menu.AddItem("10", "Кикнуть игрока");
					menu.AddItem("6", "Изменить имя игрока");
					menu.AddItem("7", "Сменить карту");
				}
				case 5: //пока не придумал
				{
					
				}
			}
			menu.Display(client, MENU_TIME_FOREVER);
		}
		else
			CGOPrintToChat(client, "Вам недоступна эта команда");
	}
	return Plugin_Handled;
} 

int Adm_UnblockUserMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
            menu.GetItem(arg2, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
            //CGOPrintToChat(client, "Вы выбрали пункт: %i (%s, инфо: %s)", arg2, szTitle, szInfo);
			int cid;
			StringToIntEx(szInfo, cid);
			DelBanDb(cid);
			SetClientListeningFlags(cid, VOICE_NORMAL);
			CGOPrintToChatAll("{GREEN}[!admin] {DEFAULT}%N снял блокировку с игрока %N", client, cid);
			LogMessage("%N(%i) снял блокировку с игрока %N(%i)", client, GetId(client), cid, GetId(cid));
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action Adm_UnblockUser(int client)
{
	Menu menu = new Menu(Adm_UnblockUserMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Разблокировать игрока");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		
		if(IsClientValid(i))
		{
			if(IsCtBannedDb(i))
			{
				char cid[8];
				char name[32];
				IntToString(i, cid, 8);
				GetClientName(i, name, 32);
				menu.AddItem(cid, name);
				//CGOPrintToChatAll("IF");
			}
			//CGOPrintToChatAll("IsCtBanned = %i", IsCtBannedDb(i));
		}
	}
	/*
	switch(IsCtBannedDb(client))
	{
		case 0:
		{
			CGOPrintToChatAll("User %N has 0 bans", client);
		}
		case 1,2,3:
		{
			CGOPrintToChatAll("User %N Has BAN, %i", client, IsCtBannedDb(client));
		}
	}
	*/ //Альтернативный вариант разблокировки
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

int Adm_SetNameMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char szInfo[64], szTitle[128];
            menu.GetItem(arg2, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
            //CGOPrintToChat(client, "Вы выбрали пункт: %i (%s, инфо: %s)", arg2, szTitle, szInfo);
			int cid;
			StringToIntEx(szInfo, cid);
			int clientid = GetClientUserId(cid);
			char buffer[64];
			FormatEx(buffer, 64, "Агент %i", clientid);
			CGOPrintToChatAll("[!admin] %N изменил имя игроку %N на %s", client, cid, buffer);
			LogMessage("%N(%i) изменил имя %N(%i)", client, GetId(client), cid, GetId(cid));
			SetClientName(cid, buffer);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Adm_SetName(int client)
{
	Menu menu = new Menu(Adm_SetNameMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Изменить имя");
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && i != client)
		{
			char cid[8];
			char name[32];
			IntToString(i, cid, 8);
			GetClientName(i, name, 32);
			menu.AddItem(cid, name);
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}




int Adm_CtBanMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			
			
			
			char info[32];
			menu.GetItem(arg2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char name[32];
			GetClientName(cid, name, 32);
			
			char f_name[32];
			GetClientName(client, f_name, 32);
			
			ChangeClientTeam(cid, CS_TEAM_T);
			CreateBanDb(cid, client, 2);
			
			
			CGOPrintToChatAll("{DEFAULT}[!admin]{DEFAULT} %s перевел игрока {RED}%s", f_name, name);
			LogMessage("%N(%i) перевел игрока %N(%i) за Т", client, GetId(client), cid, GetId(cid));
		}
	
	}
}



public Action Adm_CtBan(int client)
{
	Menu menu = new Menu(Adm_CtBanMenuH);
	menu.SetTitle("Перевести за Т");
	//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1191");//debug
	char f_name[32];
	GetClientName(client, f_name, 32);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientValid(i))
		{
			//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1203");//debug
			if(GetClientTeam(i) == CS_TEAM_CT)
			{			
				if(client != i) 
				{	
					if(g_playerStatus[i] < 2 && g_playerStatus[client] > g_playerStatus[i]) //проверка адм уровня
					{
						char name[32];
						GetClientName(i, name, 32);
						char cid[8];
						IntToString(i, cid, 8);
						menu.AddItem(cid, name);
							
					}
				}
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;	
}


public Action Adm_AdminMask(int client, int args)
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	
	if(db == null)
	{
		PrintToServer("AdminMask not connect: %s", error);
	}
	else
	{
		char buffer[255];
		FormatEx(buffer, sizeof(buffer), "UPDATE `id` SET `steamid64` = '7656119833391717500' WHERE `steamid64` = '765611983339171750'");
		if(!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("AdminMask to query 1 (error: %s)", error);
		}
		FormatEx(buffer, sizeof(buffer), "UPDATE `id` SET `steamid64` = '765611983339171750' WHERE `steamid64` = '76561198333917175'");
		if(!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("AdminMask to query 2 (error: %s)", error);
		}
		FormatEx(buffer, sizeof(buffer), "UPDATE `id` SET `steamid64` = '76561198333917175' WHERE `steamid64` = '7656119833391717500'");
		if(!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("AdminMask to query 3 (error: %s)", error);
		}
		
		g_playerStatus[client] = GetAdminPriority(GetAdminStatus(client));
	}
	delete db;
}


int DelCtH(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
			(view_as<Panel>(param2)).SetTitle(szTitle); 
		}		
		case MenuAction_Select:
		{
			char error[255]
			Database db = SQL_DefConnect(error, sizeof(error));
			
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			
			char buffer[255];
			Format(buffer, 255, "DELETE FROM `admin_lvl` WHERE `id` = '%i'", GetId(cid));
			LogMessage(buffer);
			if (!SQL_FastQuery(db, buffer))
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("SETCT: Failed to query (error: %s)", error);
			}
			
			//Action_CtPrivilegyManager(cid); //раньше она добавляла в админфайл флаг
			CGOPrintToChatAll("{GREEN}[!admin] {DEFAULT}%N снял привилегию с %N",param1, cid );
			LogMessage("Администратор %N(%i) снял привилегию СТ игроку %N(%i)", param1, GetId(param1), cid, GetId(cid));
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action AdmDelCt(int client)
{
	CGOPrintToChatAll("Инициализировано меню снятия СТ");
	Menu menu = new Menu(DelCtH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Выберите игрока:");
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_SPECTATOR)
			{
				if(StrEqual(GetAdminStatus(i), "Привилегия СТ"))
				{
					//PrintToServer("929");
					char name[32];
					GetClientName(i, name, 32);
			
					char cid[8];
					IntToString(i, cid, 8);
					menu.AddItem(cid, name);
				}
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
	
}

int AdmKickPlayerMenuH(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
			(view_as<Panel>(param2)).SetTitle(szTitle); 
		}		
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			
			CGOPrintToChatAll("{GREEN}[!admin] {DEFAULT}%N кикнул %N",param1, cid );
			LogMessage("Администратор %N(%i) кикнул %N(%i)", param1, GetId(param1), cid, GetId(cid));
			KickClient(cid, "Кикнут администратором %N\nID администратора: %i", param1, GetId(param1));
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action AdmKickPlayer(int client)
{
	Menu menu = new Menu(AdmKickPlayerMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Выберите игрока:");
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_SPECTATOR)
			{
				if(GetAdminPriority(GetAdminStatus(i)) < GetAdminPriority(GetAdminStatus(client)))
				{
					char name[32];
					GetClientName(i, name, 32);
			
					char cid[8];
					IntToString(i, cid, 8);
					menu.AddItem(cid, name);
				}
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

int Adm_CustomMuteMenuH(Menu menu, MenuAction action, int client, int args) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			(view_as<Panel>(args)).SetTitle(szTitle); 
		}		
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(args, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			g_playerMutedByAdm[cid] = true;
			CreateBanDb(cid, client, 3);
			Adm_MutePlayers();
			if(GetClientTeam(cid) == CS_TEAM_CT)
			{
				ChangeClientTeam(cid, CS_TEAM_T);
				CS_RespawnPlayer(cid);
			}
			CGOPrintToChatAll("{GREEN}[!admin] {DEFAULT}%N выдал мут %N", client, cid);
			LogMessage("Администратор %N(%i) замутил %N(%i)", client, GetId(client), cid, GetId(cid));
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Adm_CustomMute(int client)
{
	Menu menu = new Menu(Adm_CustomMuteMenuH, MenuAction_Select|MenuAction_End|MenuAction_Cancel);
	menu.SetTitle("Отключить чат и микрофон");
	
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientValid(i))
		{			
			if (GetClientTeam(i) == CS_TEAM_T || GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_SPECTATOR)
			{
				if(GetAdminPriority(GetAdminStatus(i)) < GetAdminPriority(GetAdminStatus(client)) && GetId(i) != 1)
				{
					char name[32];
					GetClientName(i, name, 32);
			
					char cid[8];
					IntToString(i, cid, 8);
					menu.AddItem(cid, name);
				}
			}
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

public void Adm_MutePlayers()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && g_playerMutedByAdm[i] == true)
		{
			SetClientListeningFlags(i, VOICE_MUTED);
		}
	}
}

int Adm_ChangeMapMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			
			
		}
		case MenuAction_Cancel:
		{
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action Adm_ChangeMap(int client)
{
	Menu menu = new Menu(Adm_ChangeMapMenuH, MenuAction_Select|MenuAction_End|MenuAction_Cancel);
	menu.SetTitle("Сменить карту");
	
	char currentmap[128];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}












public Action Func_GetTime(int client, int args)
{
	CGOPrintToChatAll("Client %N time: %i min", client, Stats_ShowTime(client));
}



char [] GetName(int id)
{
	if(id > 0)
	{
		char error[255];	
		Database db = SQL_DefConnect(error, sizeof(error));
		if(db == null)
		{
			PrintToServer("GetName not connect: %s", error);
		}
		else
		{
			char buffer[255];
			Format(buffer, 255, "SELECT `name` FROM `id` WHERE `id` = '%i'", id);
			DBResultSet query = SQL_Query(db, buffer);
			char name[64];
			while(SQL_FetchRow(query))
			{
				SQL_FetchString(query, 0, name, sizeof(name));
			}
			delete query;
			delete db;
			return name;
		}
	}
}
	

int MaxId()
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect to db: %s", error);
	}
	else 
	{	
	
			char buffer[255];
			Format(buffer, 255, "SELECT MAX(`id`) FROM `u32838_alart`.`id`");
			DBResultSet query = SQL_Query(db, buffer);
			if (query == null)
			{
				PrintToServer("SQL Query errored MaxId()");
			}
			else
			{
				while (SQL_FetchRow(query))
				{
					int temp_int;
					temp_int = SQL_FetchInt(query, 0);
					delete db;
					delete query;
					return temp_int;
				}	
			}
	}
	delete db;
	return -1;
}





public Action Action_RefreshNames(int client, int args)
{
	if(GetAdminPriority(GetAdminStatus(client)) > 3)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientValid(i) && IsClientInGame(i))
			{
				char name[32];
				Format(name, sizeof(name), "%s", GetName(GetId(i)));
				SetClientName(i, name);
			}
		}
		CGOPrintToChatAll("Администратор %N восстановил ники игрокам", client);
	}
	else
	{
		CGOPrintToChat(client, "{RED}Alart747: {DEFAULT}Вам недоступна эта команда!");
	}
}

public Action Action_Secretcommand(int client, int args)
{
	int clientid = GetId(client);
	if(clientid == 2 || clientid == 11 || clientid == 15 || clientid == 5 || clientid == 3)
	{
		switch(clientid)
		{
			case 2:
			{
				if(args == 1)
				{
					char text[256];
					GetCmdArgString(text, sizeof(text));
					//CGOPrintToChatAll("%s", text);
					if(StrEqual(text, "give_vip"))
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsClientValid(i))
							{
								CreateVipDb(GetId(i), 1, 1, client);
								LogMessage("%s выдал vip %s", GetName(client), GetName(i));
							}
						}
						CGOPrintToChatAll("Ch!p444 подарил всем {GREEN}VIP{DEFAULT} на 1 день!");
					}
					else if(StrEqual(text, "give_credits"))
					{
						//CGOPrintToChatAll("2");
					}
					else if(StrEqual(text, "give_admin"))
					{
						//CGOPrintToChatAll("3");
					}
				}
				
				
			}
			case 11:
			{
				if(args == 1)
				{
					char text[256];
					GetCmdArgString(text, sizeof(text));
					//CGOPrintToChatAll("%s", text);
					if(StrEqual(text, "give_vip"))
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsClientValid(i))
							{
								CreateVipDb(GetId(i), 1, 1, client);
								LogMessage("%s выдал vip %s", GetName(client), GetName(i));
							}
						}
						CGOPrintToChatAll("Ch!p444 подарил всем {GREEN}VIP{DEFAULT} на 1 день!");
					}
					else if(StrEqual(text, "give_credits"))
					{
						//CGOPrintToChatAll("2");
					}
					else if(StrEqual(text, "give_admin"))
					{
						//CGOPrintToChatAll("3");
					}
				}
			}
			case 15: //Святой
			{
				if(args == 1)
				{
					char text[256];
					GetCmdArgString(text, sizeof(text));
					//CGOPrintToChatAll("%s", text);
					if(StrEqual(text, "give_vip1104"))
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsClientValid(i))
							{
								CreateVipDb(GetId(i), 1, 1, client);
								LogMessage("%s выдал vip %s", GetName(client), GetName(i));
							}
						}
						CGOPrintToChatAll("Ch!p444 подарил всем {GREEN}VIP{DEFAULT} на 1 день!");
					}
					else if(StrEqual(text, "give_credits"))
					{
						//CGOPrintToChatAll("2");
					}
					else if(StrEqual(text, "give_admin"))
					{
						//CGOPrintToChatAll("3");
					}
				}
			}
			case 5: //Кузен
			{
				if(args == 1)
				{
					char text[256];
					GetCmdArgString(text, sizeof(text));
					//CGOPrintToChatAll("%s", text);
					if(StrEqual(text, "give_vip2905"))
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsClientValid(i))
							{
								CreateVipDb(GetId(i), 1, 1, client);
								LogMessage("%s выдал vip %s", GetName(client), GetName(i));
							}
						}
						CGOPrintToChatAll("Ch!p444 подарил всем {GREEN}VIP{DEFAULT} на 1 день!");
					}
					else if(StrEqual(text, "give_credits"))
					{
						//CGOPrintToChatAll("2");
					}
					else if(StrEqual(text, "give_admin"))
					{
						//CGOPrintToChatAll("3");
					}
				}
			}
			case 3: //фрим
			{
				if(args == 1)
				{
					char text[256];
					GetCmdArgString(text, sizeof(text));
					//CGOPrintToChatAll("%s", text);
					if(StrEqual(text, "give_vip"))
					{
						for(int i = 1; i <= MaxClients; i++)
						{
							if(IsClientInGame(i) && IsClientValid(i))
							{
								CreateVipDb(GetId(i), 1, 1, client);
								LogMessage("%s выдал vip %s", GetName(client), GetName(i));
							}
						}
						CGOPrintToChatAll("Ch!p444 подарил всем {GREEN}VIP{DEFAULT} на 1 день!");
					}
					else if(StrEqual(text, "give_credits"))
					{
						//CGOPrintToChatAll("2");
					}
					else if(StrEqual(text, "give_admin"))
					{
						//CGOPrintToChatAll("3");
					}
				}
			}
		}
	}
}


public Action Get_MaxId(int client, int args)
{
	CGOPrintToChat(client, "Максимальный id: %i", MaxId());
	CGOPrintToChat(client, "Это %s", GetName(MaxId()));
}

//12312312313123123131
/*
public Action Adm_SetVip(int client, int args)
{
	
	Menu menuu = new Menu(Adm_SetVipMenu);
	menuu.SetTitle("Выдать VIP");
	//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1191");//debug
	char f_name[32];
	GetClientName(client, f_name, 32);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientValid(i))
		{
			//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1203");//debug
			if(!IsPlayerVip(client)
			{			
				if(client != i) //FIXed!!! отображать себя - i+1000
				{	
					char name[32];
					GetClientName(i, name, 32);
					char cid[8];
					IntToString(i, cid, 8);
					menuu.AddItem(cid, name);
				}
			}
		}
	}
}


int Adm_SetVipMenu(Menu menu, MenuAction action, int param1, int param2) 
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", param1);
			(view_as<Panel>(param2)).SetTitle(szTitle); 
		}		
		case MenuAction_Select:
		{
			char error[255]
			Database db = SQL_DefConnect(error, sizeof(error));
			
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			char s_name[32];
			GetClientName(cid, s_name, 32);
			char f_name[32];
			GetClientName(param1, f_name, 32);
			
			char steamid2[64];
			GetClientAuthId(cid, AuthId_Steam2, steamid2, 64);
			
			char buffer[255];
			Format(buffer, 255, "INSERT INTO `vip_users` (`counter`, `id`, `name`, `steamid`, `recieved`, `last_visit`, `ingame_time`, `setter`, `lvl`, `set_date`) VALUES (NULL, '%d', '%s', '%s', NOW(),NOW() , 0, '%s', 'CT', NOW());", GetId(cid), s_name, steamid2, f_name);
			LogMessage(buffer);
			if (!SQL_FastQuery(db, buffer))
			{
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("SETCT: Failed to query (error: %s)", error);
			}
			
			//Action_CtPrivilegyManager(cid); //раньше она добавляла в админфайл флаг
			CGOPrintToChatAll("{GREEN}[!ct] {DEFAULT}Игрок %s выдал привилегию игроку %s",f_name, s_name );
			LogMessage("Администратор %s выдал привиоегию СТ игроку %s", f_name, s_name);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}
*/


