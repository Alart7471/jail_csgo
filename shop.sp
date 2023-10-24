#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdktools_entinput>
#include <sdkhooks>
#include <entity_prop_stocks>
#include <csgo_colors>
#include <clients>
#include <menus>
#include <lastrequest>

ConVar g_priceDeagle;
ConVar g_priceFlashBang;
ConVar g_priceSmokeGrenade;
ConVar g_priceHealth;
ConVar g_priceCtKit;
ConVar g_priceProtein;
ConVar g_priceSecretItem;
ConVar g_startMoney;
ConVar g_roundEndMoney;
ConVar g_roundWinMoney;
ConVar g_killCtMoney;
ConVar g_killRebelMoney;
new g_Offset_Clip1 = -1;

bool g_ShopUsed[MAXPLAYERS+1];
Handle g_Timer;
bool g_ShopAvaliable;
int g_ProteinCount = 250; // Кол-во хп после покупки протеина
//int g_casinochoose[MAXPLAYERS +1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_shop", OpenShopMenu);
	RegConsoleCmd("sm_balance", CheckShopCredits);
	RegConsoleCmd("sm_s", OpenShopMenu);
	RegConsoleCmd("sm_casino", PlayCasino);
	RegAdminCmd("sm_giveaway", Action_GiveAwayCredits, ADMFLAG_ROOT, "");
	
	RegAdminCmd("sm_global_add_credits", Global_AddCredits, ADMFLAG_ROOT, ""); 
	
	g_priceDeagle = CreateConVar("jbs_price_deagle", "120", "Sets deagle price");
	g_priceFlashBang = CreateConVar("jbs_price_flashbang", "200", "Sets flashbang price");
	g_priceSmokeGrenade = CreateConVar("jbs_price_smoke", "40", "Sets smoke price");
	g_priceHealth = CreateConVar("jbs_price_healthshot", "20", "Sets healthshot price");
	g_priceSecretItem = CreateConVar("jbs_price_secretitem", "1000", "Sets secret_item price");
	g_priceCtKit = CreateConVar("jbs_price_ctkit", "650", "Sets protein + shield total price");
	g_priceProtein = CreateConVar("jbs_price_protein", "500", "Sets Protein price");
	g_startMoney = CreateConVar("jbs_start_money", "100", "Player receives this amount of money, when he joins the server first time");
	g_roundEndMoney = CreateConVar("jbs_round_end_money", "5", "Each (dead, alive, ct, t, but not spectators) receives this amount of money, when round ends");
	g_roundWinMoney = CreateConVar("jbs_round_win_money", "5", "Each alive member of winner team gets this amount of money");
	g_killCtMoney = CreateConVar("jbs_kill_ct_money", "5", "CT killer gets this amount of money");
	g_killRebelMoney = CreateConVar("jbs_kill_rebel_money", "5", "Rebel killer gets this amount of money");	
	
	
	/*
	g_priceArmor = CreateConVar("jbs_price_armor", "200", "Sets armor price");
	g_priceProtein = CreateConVar("jbs_price_protein", "1500", "Sets protein price");
	*/
	
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
}


public Action CheckShopCredits(int client, int args)
{
	
	char buffer[255];
	Format(buffer, 255, "{GREEN}[!shop]{DEFAULT} Ваш баланс: {GREEN}%d{DEFAULT} кредитов", GetCredits(client));
	CGOPrintToChat(client, buffer);
	
	return Plugin_Handled;
	
}


void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//g_rouletteUsed = 0;
	g_ShopAvaliable = true;
	for (int i = 1; i < sizeof(g_ShopUsed); ++i) 
	{
		//LogMessage("Индекс %i прошел", i);
		//LogMessage("g_ShopUsed[%i] = FALSE", i);
		g_ShopUsed[i] = false;
	}
	g_Timer = CreateTimer(33.0, BlockShop, _, TIMER_FLAG_NO_MAPCHANGE);
	CGOPrintToChatAll("Дискорд сервера: {GREEN}discord.gg/4FNHy26Gdu");
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) != CS_TEAM_SPECTATOR)
			{
				SetCredits(i, GetCredits(i) + g_roundEndMoney.IntValue);
				char buffer[255];
				Format(buffer, 255, "{GREEN}[!shop]{DEFAULT} Вы получили %d кредитов за окончание раунда.", g_roundEndMoney.IntValue);
				CGOPrintToChat(i, buffer);
			}
			
			if (GetClientTeam(i) == event.GetInt("winner") && IsPlayerAlive(i))
			{
				SetCredits(i, GetCredits(i) + g_roundWinMoney.IntValue);
				char buffer[255];
				Format(buffer, 255, "{GREEN}[!shop]{DEFAULT} И дополнительно %d кредитов за победу!", g_roundWinMoney.IntValue);
				CGOPrintToChat(i, buffer);
			}
		}
	}
	
	//CGOPrintToChatAll("107");
	if (g_Timer != null)
	{
		KillTimer(g_Timer);
		g_Timer = null;
	}	
	//CGOPrintToChatAll("113");
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	/*
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("Could not connect: %s", error);
	} 
	else 
	{
	   	char steamid[64];
	   	GetClientAuthId(client, AuthId_Steam2, steamid, 64);
	    	
	   	char query_text[512]; 
	   	Format(query_text, 512, "SELECT `credits` FROM `id` WHERE `steamid` = '%s'", steamid);
	   	DBResultSet query = SQL_Query(db, query_text);
		    	
	   	if (query == null)
	   	{
	   		char buffer[255];
			Format(buffer, 255, "INSERT INTO `id` (`steamid`, `credits`) VALUES ('%s', '%d');", steamid, g_startMoney.IntValue);
			if (!SQL_FastQuery(db, buffer))
			{
				char error[255];
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
			}
			Format(buffer, 255, "[{GREEN}SHOP{DEFAULT}] Стартовый баланс: {GREEN}%d{DEFAULT} кредитов", g_startMoney.IntValue);
			CGOPrintToChat(client, buffer);
	   	} 
	   	else 
	   	{
	   		if (SQL_GetRowCount(query) == 0)
			{
				char buffer[255];
				Format(buffer, 255, "INSERT INTO `id` (`steamid`, `credits`) VALUES ('%s', '%d');", steamid, g_startMoney.IntValue);
				if (!SQL_FastQuery(db, buffer))
				{
					char error[255];
					SQL_GetError(db, error, sizeof(error));
					PrintToServer("Failed to query (error: %s)", error);
				}
				Format(buffer, 255, "[{GREEN}SHOP{DEFAULT}] Стартовый баланс: {GREEN}%d{DEFAULT} кредитов", g_startMoney.IntValue);
				CGOPrintToChat(client, buffer);
			}
	   		
	   		delete query;
	   	}	
		delete db;
	}
	*/
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int killed = GetClientOfUserId(event.GetInt("userid"));
	
	if (killer != 0 &&  killed != 0 && killer != killed && IsClientInGame(killed) && IsClientInGame(killer))
	{
		if (GetClientTeam(killer) == CS_TEAM_T && GetClientTeam(killed) == CS_TEAM_CT)
		{			
			SetCredits(killer, GetCredits(killer) + g_killCtMoney.IntValue);
			char buffer[255];
			Format(buffer, 255, "{GREEN}[!shop]{DEFAULT} Вы получили {GREEN}%d{DEFAULT} кредит за убийство КТ!", g_killCtMoney.IntValue);
			CGOPrintToChat(killer, buffer);								
		}
		else if (GetClientTeam(killer) == CS_TEAM_CT && IsClientRebel(killed))
		{
			SetCredits(killer, GetCredits(killer) + g_killRebelMoney.IntValue);
			char buffer[255];
			Format(buffer, 255, "{GREEN}[!shop]{DEFAULT} Вы получили {GREEN}%d{DEFAULT} кредитов за убийство бунтующего заключенного!", g_killRebelMoney.IntValue);
			CGOPrintToChat(killer, buffer);
		}
	}
}


Action BlockShop(Handle timer)
{
	g_ShopAvaliable = false;
	//CGOPrintToChatAll("196");
	g_Timer = null;
	return Plugin_Handled;
}


int GetCredits(int client)
{
	int credits;
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("[SHOP.getcredits]Could not connect: %s", error);
		delete db;
		return 0;
	} 
	else 
	{
	   	char steamid[64];
	   	GetClientAuthId(client, AuthId_Steam2, steamid, 64);	
	   	char query_text[512]; 
	   	Format(query_text, 512, "SELECT `credits` FROM `id` WHERE `id` = '%i'", GetId(client));
	   	DBResultSet query = SQL_Query(db, query_text);
		    	
	   	if (query == null)
	   	{
	   		credits = 0;
	   	} 
	   	else 
	   	{
	   		while (SQL_FetchRow(query))
	  		{						
	   			credits = SQL_FetchInt(query, 0);
				delete query;
				delete db;
				return credits;
	   		} 
	   		delete query;
	   	}
		delete query;
		delete db;
		return 0;
	}
}

int SetCredits(int client, int amount)
{	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	//CGOPrintToChatAll("SET CREDITS 243");	    
	if (db == null)
	{
	  	PrintToServer("Could not connect: %s", error);
	} 
	else 
	{
		//LogMessage("SET 1");
	    	
	   	char query_text[512]; 
	   	Format(query_text, 512, "UPDATE `id` SET `credits` = '%d' WHERE `id` = '%i';", amount, GetId(client));
		//CGOPrintToChatAll("SET CREDITS 256");
	   	if (!SQL_FastQuery(db, query_text))
		{
			LogMessage("SET 2");
			char error[255];
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		delete db;
	}
	
	return amount;
	//CGOPrintToChatAll("SET CREDITS 265");
}


public Action OpenShopMenu(int client, int args)
{
	//if(g_ShopAvaliable == true)
	//{
		if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			ShopMenu(client, true);
			//CGOPrintToChat(client, "[{GREEN}!shop{DEFAULT}] {PURPLE}Открылся CT магазин");
		}
		else if(client > 0 && IsClientInGame(client) && (GetClientTeam(client) == CS_TEAM_T || GetClientTeam(client) == CS_TEAM_SPECTATOR))
		{
			ShopMenu(client, false);
			//CGOPrintToChat(client, "[{GREEN}!shop{DEFAULT}] {PURPLE}Открылся T магазин");
		}
	//}
	//else
	//{
	//	CGOPrintToChat(client, "[{GREEN}!shop{DEFAULT}] Магазин работает только первые 30 секунд!!");
	//}
}

//debug
stock Action Global_AddCredits(int client, int args)
{	
	int autoinc;

	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	
	if(db == null)
	{
		PrintToServer("Could not connect: %s", error);
	}
	else
	{
		char query_text[512]; 
	   	Format(query_text, 512, "SELECT MAX(id)FROM `id`;");
		DBResultSet query = SQL_Query(db, query_text);
		
		if (query == null)
	   	{
	   		autoinc = 0;
			LogMessage("args 0");
	   	} 
	   	else 
	   	{
			LogMessage("args != 0");
	   		while (SQL_FetchRow(query))
	  		{						
	   			autoinc = SQL_FetchInt(query, 0);
	   		} 
	   		
	   		delete query;
	   	}	

	}
	LogMessage("%i", autoinc);
	//CGOPrintToChatAll("AUTO_INCREMENT: %i", autoinc);
	
	for(int i = 1; i <= autoinc; i++)
	{
		int credits;
		char query_t[512]; 
	   	Format(query_t, 512, "SELECT `credits` FROM `id` WHERE `id` = '%i'", i);
	   	DBResultSet queryy = SQL_Query(db, query_t);
		   
	   	if (queryy == null)
	   	{
	   		credits = 0;
	   	} 
	   	else 
	   	{
	   		while (SQL_FetchRow(queryy))
	  		{						
	   			credits = SQL_FetchInt(queryy, 0);
	   		} 
	   		
	   		delete queryy;
	   	}	

		
		int newcredits;
		newcredits = credits + 500;
		
		char query_textt[512]; 	
	   	Format(query_textt, 512, "UPDATE `id` SET `credits` = '%d' WHERE `id`.`id` = '%i';", newcredits, i);
		
	   	if (!SQL_FastQuery(db, query_textt))
		{
			char error[255];
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		
	
	
		
	}
	delete db;
	
}


int ShopMenuHandler(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(arg2, info, sizeof(info), style);
			
			switch(arg2)
			{
				case 0: 
					return (GetCredits(client) >= g_priceHealth.IntValue) ?  style : ITEMDRAW_DISABLED;
				case 1: 
					return (GetCredits(client) >= g_priceSmokeGrenade.IntValue) ? style : ITEMDRAW_DISABLED;
				case 2: 
					return (GetClientTeam(client) == CS_TEAM_T) ? (GetCredits(client) >= g_priceDeagle.IntValue) ? style : ITEMDRAW_DISABLED : (GetCredits(client) >= g_priceCtKit.IntValue) ? style : ITEMDRAW_DISABLED;
				case 3: 
					return (GetCredits(client) >= g_priceFlashBang.IntValue) ? style : ITEMDRAW_DISABLED;
				case 4: 
					return (GetCredits(client) >= g_priceProtein.IntValue) ? style : ITEMDRAW_DISABLED;
				case 5: 
					return (GetCredits(client) >= 50) ? style : ITEMDRAW_DISABLED;
				case 6: 
					return (GetCredits(client) >= 100) ? style : ITEMDRAW_DISABLED;
			}
			
			/*
			if(arg2 == 0)
			{
				return (GetCredits(client) >= g_priceHealth.IntValue) ? style : ITEMDRAW_DISABLED;
				// *
				if(GetCredits(client) >= g_priceHealth.IntValue)
				{
					return style;
				}
				else
				{
					return ITEMDRAW_DISABLED;
				}
				// *
			}
			else if(arg2 == 1)
			{
				return (GetCredits(client) >= g_priceSmokeGrenade.IntValue) ? style : ITEMDRAW_DISABLED;
			}
			else if(arg2 == 2)
			{
				return (GetClientTeam(client) == CS_TEAM_T) ? (GetCredits(client) >= g_priceDeagle.IntValue) ? style : ITEMDRAW_DISABLED : (GetCredits(client) >= g_priceCtKit.IntValue) ? style : ITEMDRAW_DISABLED;
			}
			else if(arg2 == 3)
			{
				return (GetCredits(client) >= g_priceFlashBang.IntValue) ? style : ITEMDRAW_DISABLED;
			}
			else if(arg2 == 4)
			{
				return (GetCredits(client) >= g_priceProtein.IntValue) ? style : ITEMDRAW_DISABLED;
			}
			else if(arg2 == 5)
			{
				return (GetCredits(client) >= 5) ? style : ITEMDRAW_DISABLED;
			}
			*/
		}
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			view_as<Panel>(arg2).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char buffer_shopUnavailable[255];
			Format(buffer_shopUnavailable, 255, "[{GREEN}!shop{DEFAULT}] Магазин работает только первые 30 секунд!");
			char buffer_shopUsed[255];
			Format(buffer_shopUsed, 255, "[{GREEN}!shop{DEFAULT}] Магазин можно использовать только раз за раунд!");
			char buffer_PokaNePridumal[255];
			Format(buffer_PokaNePridumal, 255, "[{GREEN}!shop{DEFAULT}] Ваш баланс: {GREEN}%d{DEFAULT} кредитов", GetCredits(client));
			switch(arg2)
			{
				case 0,1,2,3,4:
					(g_ShopAvaliable) ? (!g_ShopUsed[client]) ? ShopMenuAction_Buy(client, arg2) : CGOPrintToChat(client, buffer_shopUsed) : CGOPrintToChat(client, buffer_shopUnavailable);
				case 5,6: 
					ShopMenuAction_Buy(client, arg2);
					
			}
			//(g_ShopAvaliable) ? (!g_ShopUsed[client]) ? ShopMenuAction_Buy(client, arg2) : CGOPrintToChat(client, buffer_shopUsed) : CGOPrintToChat(client, buffer_shopUnavailable);
				
			
			/* 
			if(arg2 == 0)
			{
				
			}
			else if(arg2 == 1)
			{
				
			}
			else if(arg2 == 2)
			{
				
			}
			else if(arg2 == 3)
			{
				
			}
			else if(arg2 == 4)
			{
				
			}
			else if(arg2 == 5)
			{
				
			}
			*/
		}
		case MenuAction_End:
		{
			delete menu;
		}
		
	}
}

// ??? Сделать один буфер и переформатировать

public Action ShopMenu(int client, bool args)
{
	Menu menu = new Menu(ShopMenuHandler, MenuAction_Select|MenuAction_DrawItem|MenuAction_End);
	if(args)
	{
		char buf1[64];
		char buf2[64];
		char buf3[64];
		char buf4[64];
		char buf5[64];
		
		FormatEx(buf1, 64, "Купить аптечку [%d]", g_priceHealth.IntValue);
		FormatEx(buf2, 64, "Купить дымовую гранату [%d]", g_priceSmokeGrenade.IntValue);
		FormatEx(buf3, 64, "Купить набор охранника [%d]", g_priceCtKit.IntValue);
		FormatEx(buf4, 64, "Купить световую гранату [%d]", g_priceFlashBang.IntValue);
		FormatEx(buf5, 64, "Купить протеин [%d]", g_priceProtein.IntValue);
		
		menu.SetTitle("Чёрный рынок. Баланс: %i", GetCredits(client));
		menu.AddItem("1", buf1);//"Купить аптечку %d", g_priceHealth.IntValue);
		menu.AddItem("2", buf2);//"Купить дымовую гранату %d", g_priceSmokeGrenade.IntValue);
		menu.AddItem("3", buf3);//"Купить набор охранника %d", g_priceCtKit.IntValue);
		menu.AddItem("4", buf4);//"Купить световую гранату %d", g_priceFlashBang.IntValue);
		menu.AddItem("5", buf5);//"Купить протеин %d", g_priceProtein.IntValue);
		menu.AddItem("6", "Передать кредиты");
		menu.AddItem("7", "Купить фишки");
	}
	else
	{
		char buf1[64];
		char buf2[64];
		char buf3[64];
		char buf4[64];
		char buf5[64];
		
		FormatEx(buf1, 64, "Купить аптечку [%d]", g_priceHealth.IntValue);
		FormatEx(buf2, 64, "Купить дымовую гранату [%d]", g_priceSmokeGrenade.IntValue);
		FormatEx(buf3, 64, "Купить пистолет [%d]", g_priceDeagle.IntValue);
		FormatEx(buf4, 64, "Купить световую гранату [%d]", g_priceFlashBang.IntValue);
		FormatEx(buf5, 64, "Купить протеин [%d]", g_priceProtein.IntValue);
		
		menu.SetTitle("Чёрный рынок. Баланс: %i", GetCredits(client));
		menu.AddItem("1", buf1);//"Купить аптечку %d", g_priceHealth.IntValue);
		menu.AddItem("2", buf2);//"Купить дымовую гранату %d", g_priceSmokeGrenade.IntValue);
		menu.AddItem("3", buf3);//"Купить набор охранника %d", g_priceCtKit.IntValue);
		menu.AddItem("4", buf4);//"Купить световую гранату %d", g_priceFlashBang.IntValue);
		menu.AddItem("5", buf5);//"Купить протеин %d", g_priceProtein.IntValue);
		menu.AddItem("6", "Передать кредиты");
		menu.AddItem("7", "Купить фишки");
		
		
		
		/*menu.AddItem("1", "Купить аптечку [%d]", g_priceHealth.IntValue);
		menu.AddItem("2", "Купить дымовую гранату [%d]", g_priceSmokeGrenade.IntValue);
		menu.AddItem("3", "Купить пистолет [%d]", g_priceDeagle.IntValue);
		menu.AddItem("4", "Купить световую гранату [%d]", g_priceFlashBang.IntValue);
		menu.AddItem("5", "Купить протеин [%d]", g_priceProtein.IntValue);
		menu.AddItem("6", "Передать кредиты");*/
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}




// SHOP GETING ITEMS

public Action ShopMenuAction_Buy(int client, int args)
{
	if(IsClientValid(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		switch(args)
		{
			case 0: 
			{
				SetCredits(client, GetCredits(client) - g_priceHealth.IntValue);
				g_ShopUsed[client] = true;
				GivePlayerItem(client, "weapon_healthshot");
				CGOPrintToChatAll("Стукач: Кому-то пронесли аптечку.");
			}
			case 1: 
			{
				SetCredits(client, GetCredits(client) - g_priceSmokeGrenade.IntValue);
				g_ShopUsed[client] = true;
				GivePlayerItem(client, "weapon_smokegrenade");
				CGOPrintToChatAll("Стукач: Кому-то пронесли дымовую гранату.");
			}
			case 2: 
			{
				if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
				{
					SetCredits(client, GetCredits(client) - g_priceCtKit.IntValue);
					g_ShopUsed[client] = true;
					GivePlayerItem(client, "weapon_shield");
					SetEntityHealth(client, g_ProteinCount);
					CGOPrintToChatAll("Стукач: Кому-то пронесли набор охранника.");
			
				}
				else if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
				{
					SetCredits(client, GetCredits(client) - g_priceDeagle.IntValue);
					g_ShopUsed[client] = true;
					new weapon;
					weapon = GivePlayerItem(client, "weapon_deagle");
					EquipPlayerWeapon(client, weapon);
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
					g_Offset_Clip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
					SetEntData(weapon, g_Offset_Clip1, 7);
					SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
					CGOPrintToChatAll("Стукач: Кому-то пронесли пистолет.");
				}
			}
			case 3: 
			{
				SetCredits(client, GetCredits(client) - g_priceFlashBang.IntValue);
				g_ShopUsed[client] = true;
				GivePlayerItem(client, "weapon_flashbang");
				CGOPrintToChatAll("Стукач: Кому-то пронесли световую гранату.");
			}
			case 4: 
			{
				SetCredits(client, GetCredits(client) - g_priceProtein.IntValue);
				g_ShopUsed[client] = true;
				SetEntityHealth(client, g_ProteinCount);
				CGOPrintToChatAll("Стукач: Кому-то пронесли протеин.");
			}
			case 5: 
			{
				//Передача
				//SetCredits(client, GetCredits(client) - g_priceHealth.IntValue);
				//CGOPrintToChatAll("На стадии тестирования");
				ShopMenu_Transfer(client);
			}
			case 6: 
			{
				//Покупка фишек
				//SetCredits(client, GetCredits(client) - g_priceHealth.IntValue);
				CGOPrintToChat(client, "На стадии тестирования {LIME}1");
				PlayCasinoBuyFishki(client);
			}
		}
	}
	else if(IsClientValid(client) && IsClientInGame(client))
	{
		switch(args)
		{
			case 5: 
			{
				//Передача
				//SetCredits(client, GetCredits(client) - g_priceHealth.IntValue);
				CGOPrintToChatAll("На стадии тестирования");
				ShopMenu_Transfer(client);
			}
			case 6: 
			{
				//Покупка фишек
				//SetCredits(client, GetCredits(client) - g_priceHealth.IntValue);
				CGOPrintToChat(client, "На стадии тестирования {LIME}1");
				PlayCasinoBuyFishki(client);
			}
		}
	}
	return Plugin_Handled;
}

int ShopMenu_TransferMenuH(Menu menu, MenuAction action, int client, int arg2)
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
			ShopMenu_TransferPay(client, cid);
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

}

public Action ShopMenu_Transfer(int client)
{
	Menu menu = new Menu(ShopMenu_TransferMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Передать кредиты");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(i > 0 && IsClientInGame(i) && i != client)
		{
			char cid[8];
			IntToString(i, cid, 8);
			char name[32];
			GetClientName(i, name, sizeof(name));
			menu.AddItem(cid, name);
		}
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}


int ShopMenu_TransferPayMenuH(Menu menu, MenuAction action, int client, int arg2)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(arg2, info, sizeof(info), style);
			
			
			
			//CGOPrintToChatAll("1 - %s", info);
			//CGOPrintToChatAll("2 - %i", arg2);
			
			//char szInfo[64], szTitle[128];
            //menu.GetItem(arg2, szInfo, sizeof(szInfo), _, szTitle, sizeof(szTitle));
           // CGOPrintToChat(client, "Вы выбрали пункт: %i (%s, инфо: %s)", arg2, szTitle, szInfo);

			switch(arg2)
			{
				case 0:
					return (GetCredits(client) >= 50) ? style : ITEMDRAW_DISABLED;
				case 1:
					return (GetCredits(client) >= 100) ? style : ITEMDRAW_DISABLED;
				case 2:
					return (GetCredits(client) >= 250) ? style : ITEMDRAW_DISABLED;
				case 3:
					return (GetCredits(client) >= 500) ? style : ITEMDRAW_DISABLED;
				case 4:
					return (GetCredits(client) >= 1000) ? style : ITEMDRAW_DISABLED;
				case 5:
					return (GetCredits(client) >= 5000) ? style : ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
			(view_as<Panel>(arg2)).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(arg2, info, sizeof(info));
			
			int cid;
			StringToIntEx(info, cid)
			
			switch(arg2)
			{
			case 0:
			{
				SetCredits(client, GetCredits(client) - 50);
				SetCredits(cid, GetCredits(cid) + 50);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 50 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел вам 50 кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 50 кредитов", client, GetId(client), cid, GetId(cid));
			}
			case 1:
			{
				SetCredits(client, GetCredits(client) - 100);
				SetCredits(cid, GetCredits(cid) + 100);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 100 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел вам 100 кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 100 кредитов", client, GetId(client), cid, GetId(cid));
			}
			case 2:
			{
				SetCredits(client, GetCredits(client) - 250);
				SetCredits(cid, GetCredits(cid) + 250);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 250 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел 250 вам кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 250 кредитов", client, GetId(client), cid, GetId(cid));
			}
			case 3:
			{
				SetCredits(client, GetCredits(client) - 500);
				SetCredits(cid, GetCredits(cid) + 500);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 500 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел вам 500 кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 500 кредитов", client, GetId(client), cid, GetId(cid));
			}
			case 4:
			{
				SetCredits(client, GetCredits(client) - 1000);
				SetCredits(cid, GetCredits(cid) + 1000);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 1000 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел вам 1000 кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 1000 кредитов", client, GetId(client), cid, GetId(cid));
			}
			case 5:
			{
				SetCredits(client, GetCredits(client) - 5000);
				SetCredits(cid, GetCredits(cid) + 5000);
				
				CGOPrintToChat(client, "{GREEN}[!shop] {DEFAULT}Вы успешно перевели %N 5000 кредитов!", cid);
				CGOPrintToChat(cid, "{GREEN}[!shop] {DEFAULT}%N перевел вам 5000 кредитов", client);
				LogMessage("[!shop] %N(%i) перевел %N(%i) 5000 кредитов", client, GetId(client), cid, GetId(cid));
			}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action ShopMenu_TransferPay(int client, int arg2)
{
	//arg2 - клиент, кому передать кредиты
	Menu menu = new Menu(ShopMenu_TransferPayMenuH, MenuAction_Select|MenuAction_DrawItem|MenuAction_End);
	menu.SetTitle("Сумма перевода");
	
	char cid[8];
	IntToString(arg2, cid, sizeof(cid));
	
	menu.AddItem(cid, "50");
	menu.AddItem(cid, "100");
	menu.AddItem(cid, "250");
	menu.AddItem(cid, "500");
	menu.AddItem(cid, "1000");
	menu.AddItem(cid, "5000");
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

bool IsClientValid(int client)
{
	return ((client > 0) && (client <= MaxClients) && IsClientInGame(client));
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


int PlayCasinoMenuH(Menu menu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(args).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			//client - тот, кто вызвал меню
			//cid - тот, кого он выбрал в меню
			
			
			char info[32];
			menu.GetItem(args, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			PlayCasinoBetCount(client, cid);
			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action PlayCasino(int client, int args)
{
	if(GetCredits(client) > 50 ){
	Menu menu = new Menu(PlayCasinoMenuH, MenuAction_Select|MenuAction_End);
	menu.SetTitle("Выбрать игрока:");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsClientValid(i))
		{
			//CGOPrintToChatAll("{RED}[!ct]{DEFAULT}1203");//debug
			if(GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T)
			{			
				if(client != i) //FIXed!!! отображать себя - i+1000
				{	
					if(GetFishki(i) > 50) //проверка адм уровня
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
	else
	{
		CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747]{DEFAULT} Для игры у вас должно быть больше {GREEN}50 {DEFAULT}кредитов!");
	}
	
}

int PlayCasinoMenuBetMenuH(Menu menu, MenuAction action, int client, int arg)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(arg, info, sizeof(info), style);
			
			int cid = -1;
			StringToIntEx(info, cid);
			
			switch(arg)
			{
				case 0: 
					return (GetFishki(client) >= 50 && GetFishki(cid) >= 50)  ? style : ITEMDRAW_DISABLED;
				case 1: 
					return (GetFishki(client) >= 100 && GetFishki(cid) >= 100)  ? style : ITEMDRAW_DISABLED;
				case 2: 
					return (GetFishki(client) >= 250 && GetFishki(cid) >= 250)  ? style : ITEMDRAW_DISABLED;
				case 3: 
					return (GetFishki(client) >= 500 && GetFishki(cid) >= 500)  ? style : ITEMDRAW_DISABLED;
				case 4: 
					return (GetFishki(client) >= 1000 && GetFishki(cid) >= 1000)  ? style : ITEMDRAW_DISABLED;
				case 5: 
					return (GetFishki(client) >= 5000 && GetFishki(cid) >= 5000)  ? style : ITEMDRAW_DISABLED;
				case 6: 
					return (GetFishki(client) >= 10000 && GetFishki(cid) >= 10000)  ? style : ITEMDRAW_DISABLED;
				case 7: 
					return (GetFishki(client) >= 15000 && GetFishki(cid) >= 15000)  ? style : ITEMDRAW_DISABLED;
				case 8: 
					return (GetFishki(client) >= 20000 && GetFishki(cid) >= 20000)  ? style : ITEMDRAW_DISABLED;
				case 9: 
					return (GetFishki(client) >= 25000 && GetFishki(cid) >= 25000)  ? style : ITEMDRAW_DISABLED;
				case 10: return style;
			}
		}
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(arg).SetTitle(szTitle); 
		}
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(arg, info, sizeof(info));
			int cid = -1;
			StringToIntEx(info, cid);
			
			switch(arg)
			{
				case 0:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 50");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(50);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 1:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 100");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(100);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 2:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 250");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(250);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 3:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 500");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(500);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 4:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 1000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(1000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 5:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 5000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(5000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 6:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 10000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(10000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 7:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 15000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(15000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 8:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 20000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(20000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 9:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: 25000");
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					hPack.WriteCell(25000);
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
				case 10:
				{
					CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N спровоцировал %N поиграть в казино!", client, cid);
					DataPack hPack = new DataPack();
					hPack.WriteCell(client);
					hPack.WriteCell(cid);
					int temp_one = GetCredits(client); //25
					int temp_two = GetCredits(cid); //10
					if(temp_one == temp_two)
					{
						hPack.WriteCell(temp_one);
						CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: Ва-банк");
					}
					else if(temp_one > temp_two)
					{
						hPack.WriteCell(temp_two);
						CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: Ва-банк %N - %i", cid, temp_two);
					}
					else if(temp_one < temp_two)
					{
						hPack.WriteCell(temp_one);
						CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ставка: Ва-банк %N - %i", client, temp_one);
					}
					CreateTimer(2.5, PlayCasinoStart, hPack);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}


public Action PlayCasinoBetCount(int client, int target)
{
	//client - тот, кто вызвал
	//target - тот, кого вызвали
	
	//g_casinochoose[client] = target;
	Menu menu = new Menu(PlayCasinoMenuBetMenuH, MenuAction_Select|MenuAction_DrawItem|MenuAction_End);
	
	menu.SetTitle("Ставка:");
	
	char cid[8];
	IntToString(target, cid, sizeof(cid));
	
	menu.AddItem(cid, "50");
	menu.AddItem(cid, "100");
	menu.AddItem(cid, "250");
	menu.AddItem(cid, "500");
	menu.AddItem(cid, "1000");
	menu.AddItem(cid, "5000");
	menu.AddItem(cid, "10000");
	menu.AddItem(cid, "15000");
	menu.AddItem(cid, "20000");
	menu.AddItem(cid, "25000");
	menu.AddItem(cid, "Ва-банк");
	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}



public Action PlayCasinoStart(Handle timer, Handle hDataPack)
{
	//client - кто вызвал
	//target - кого вызвали
	//bet - ставка
	DataPack hPack = view_as<DataPack>(hDataPack);
	hPack.Reset();
	/*
	int client = data[0];
	int target = data[1];
	int bet = data[2];
	*/
	int client = hPack.ReadCell();
	int target = hPack.ReadCell();
	int bet = hPack.ReadCell();
	
	int a1 = GetRandomInt(1, 6);
	int a2 = GetRandomInt(1, 6);
	int b1 = GetRandomInt(1, 6);
	int b2 = GetRandomInt(1, 6);
	//CGOPrintToChatAll("a1 - %i, a2 - %i, b1 - %i, b2 - %i", a1, a2, b1, b2);
	
	if(a1+a2 > b1+b2)
	{
		if(GetFishki(target) >= bet && GetFishki(client) >= bet)
		{
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N выиграл у %N {GREEN}%i {DEFAULT}кредитов!", client, target, bet);
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", client, a1+a2);
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", target, b1+b2);
			SetFishki(client, GetFishki(client) + bet);
			SetFishki(target, GetFishki(target) - bet);
			LogMessage("[casino] %N(%i) WIN %N(%i) | %i", client, GetId(client), target, GetId(target), bet);
		}
		else
		{
			CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747]{DEFAULT} У игрока уже нет такой суммы!");
		}
	}
	else if(a1+a2 < b1+b2)
	{
		if(GetFishki(client) >= bet && GetFishki(target) >= bet)
		{
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} %N проиграл %N {GREEN}%i {DEFAULT}кредитов!", client, target, bet);
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", client, a1+a2);
			CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", target, b1+b2);
			SetFishki(client, GetFishki(client) - bet);
			SetFishki(target, GetFishki(target) + bet);
			LogMessage("[casino] %N(%i) WIN %N(%i) | %i", target, GetId(target), client, GetId(client), bet);
		}
		else
		{
			CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747]{DEFAULT} У вас или у противника уже нет такой суммы!");
		}
	}
	else //РАВНО
	{
		CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} Ничья!");
		CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", client, a1+a2);
		CGOPrintToChatAll("{LIGHTRED}[АЗИНО747]{DEFAULT} У %N выпало: %i ", target, b1+b2);
	}
	KillTimer(timer);
	timer = null;
	return Plugin_Handled;
}


public Action Action_GiveAwayCredits(int client, int args)
{
	if(args < 1)
	{
		CGOPrintToChat(client, "{GREEN}[!giveaway] {DEFAULT}Использование: !giveaway <сумма кредитов на розыгрыш>");
	}
	else
	{
		char message[192];
		GetCmdArgString(message, 192);
		//CGOPrintToChatAll("Message - %s", message);
		int count;
		StringToIntEx(message, count);
		//CGOPrintToChatAll("Cout - %i", count);
		if(count > 0)
		{
			LogMessage("%N(%i) запустил розыгрыш %i кредитов", client, GetId(client), count)
			Action_GiveAwayCreditsStart(client, count);
		}
		else
		{
			CGOPrintToChat(client, "{GREEN}[!giveaway] {DEFAULT}Использование: !giveaway <сумма кредитов на розыгрыш>");
		}
	}
}

public Action Action_GiveAwayCreditsStart(int client, int sum)
{
	//sum - кол-во кредов на розыгрыш
	
	CGOPrintToChatAll("Администратор начал розыгрыш %i кредитов", sum);
	
	int res[MAXPLAYERS+1];
	int resultid;
	int checker = -100;
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i) && IsClientInGame(i))
		{
			res[i] = GetRandomInt(0, 100);
		}
	}
	for(int i = 1; i <= sizeof(res); i++)
	{
		if(IsClientValid(i) && IsClientInGame(i) && res[i] > checker)
		{
			checker = res[i];
			resultid = i;
		}
	}
	//CGOPrintToChatAll("Result - %i", resultid);
	if(IsClientValid(resultid))
	{
		LogMessage("%N(%i) забрал с розыгрыша %i кредитов", resultid, GetId(resultid), sum);
		CGOPrintToChatAll("Победил игрок %N", resultid);
		SetCredits(resultid, GetCredits(resultid) + sum);
	}
}

int PlayCasinoBuyFishkiMenuH(Menu menu, MenuAction action, int client, int args)
{
	switch(action)
	{
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(args, info, sizeof(info), style);
			
			switch(args)
			{
				case 0:
					return (GetCredits(client) >= 500) ? style : ITEMDRAW_DISABLED;
				case 1:
					return (GetCredits(client) >= 1000) ? style : ITEMDRAW_DISABLED;
				case 2:
					return (GetCredits(client) >= 2500) ? style : ITEMDRAW_DISABLED;
				case 3:
					return (GetCredits(client) >= 5000) ? style : ITEMDRAW_DISABLED;
				case 4:
					return (GetCredits(client) >= 10000) ? style : ITEMDRAW_DISABLED;
				case 5:
					return (GetCredits(client) >= 50000) ? style : ITEMDRAW_DISABLED;
			}
		}
		case MenuAction_Display:
		{
			char szTitle[128];
			FormatEx(szTitle, sizeof(szTitle), "%T", "фраза_из_перевода", client);
            view_as<Panel>(args).SetTitle(szTitle);
		}
		case MenuAction_Select:
		{
			switch(args)
			{
				case 0:
				{
					if(GetCredits(client) >= 500)
					{
						LogMessage("%N(%id) купил 50 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-500);
						SetFishki(client, GetFishki(client)+50);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 50 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
				case 1:
				{
					if(GetCredits(client) >= 1000)
					{
						LogMessage("%N(%id) купил 100 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-1000);
						SetFishki(client, GetFishki(client)+100);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 100 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
				case 2:
				{
					if(GetCredits(client) >= 2500)
					{
						LogMessage("%N(%id) купил 250 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-2500);
						SetFishki(client, GetFishki(client)+250);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 250 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
				case 3:
				{
					if(GetCredits(client) >= 5000)
					{
						LogMessage("%N(%id) купил 50 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-5000);
						SetFishki(client, GetFishki(client)+500);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 500 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
				case 4:
				{
					if(GetCredits(client) >= 10000)
					{
						LogMessage("%N(%id) купил 50 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-10000);
						SetFishki(client, GetFishki(client)+1000);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 1000 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
				case 5:
				{
					if(GetCredits(client) >= 50000)
					{
						LogMessage("%N(%id) купил 50 фишек", client, GetId(client));
						SetCredits(client, GetCredits(client)-50000);
						SetFishki(client, GetFishki(client)+5000);
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}Вы купили 5000 фишек!");
						return Plugin_Handled;
					}
					else
					{
						CGOPrintToChat(client, "{LIGHTRED}[АЗИНО747] {DEFAULT}У вас не хватает фишек!");
						return Plugin_Handled;
					}
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action PlayCasinoBuyFishki(int client)
{
	Menu menu = new Menu(PlayCasinoBuyFishkiMenuH, MenuAction_Select|MenuAction_DrawItem|MenuAction_End);
	
	menu.SetTitle("Купить фишки:");
	
	char cid[8] = "";
	menu.AddItem(cid, "50 фишек [500]");
	menu.AddItem(cid, "100 фишек [1000]");
	menu.AddItem(cid, "250 фишек [2500]");
	menu.AddItem(cid, "500 фишек [5000]");
	menu.AddItem(cid, "1000 фишек [10000]");
	menu.AddItem(cid, "5000 фишек [50000]");

	
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
	
}


int GetFishki(int client)
{
	int credits;
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
		    
	if (db == null)
	{
	  	PrintToServer("[SHOP.getfishki]Could not connect: %s", error);
		delete db;
		return 0;
	} 
	else 
	{
	   	char steamid[64];
	   	GetClientAuthId(client, AuthId_Steam2, steamid, 64);	
	   	char query_text[512]; 
	   	Format(query_text, 512, "SELECT `casino` FROM `id` WHERE `id` = '%i'", GetId(client));
	   	DBResultSet query = SQL_Query(db, query_text);
	   	if (query == null)
	   	{
	   		credits = 0;
			delete db;
			delete query;
			return 0;
	   	} 
	   	else 
	   	{
	   		while (SQL_FetchRow(query))
	  		{						
	   			credits = SQL_FetchInt(query, 0);
				delete query;
				delete db;
				return credits;
	   		} 
	   		delete query;
	   	}
	}
}


int SetFishki(int client, int amount)
{	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	//CGOPrintToChatAll("SET CREDITS 243");	    
	if (db == null)
	{
	  	PrintToServer("Could not connect: %s", error);
		delete db;
		return 0;
	} 
	else 
	{
		//LogMessage("SET 1");
	    	
	   	char query_text[512]; 
	   	Format(query_text, 512, "UPDATE `id` SET `casino` = '%d' WHERE `id` = '%i';", amount, GetId(client));
		//CGOPrintToChatAll("SET CREDITS 256");
	   	if (!SQL_FastQuery(db, query_text))
		{
			char error[255];
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		delete db;
	}
	
	return amount;
	//CGOPrintToChatAll("SET CREDITS 265");
}