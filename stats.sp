#include <sourcemod>
#include <cstrike>
#include <clients>
#include <console>
#include <sdktools>
#include <sdkhooks>
#include <csgo_colors>


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Stats_SaveTime", Native_SaveTime);
	CreateNative("Stats_CreateDb", Native_CreateDb);
	CreateNative("Stats_IsDbCreated", Native_IsDbCreated);
	CreateNative("Stats_ShowTime", Native_ShowTime);
	return APLRes_Success;
}

public int Native_SaveTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	LogMessage("Время %N - %f", client, GetClientTime(client));
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	if(db == null)
	{
		PrintToServer("STATSdb not connect: %s", error);
		delete db;
		return false;
	}
	else
	{
		char buffer[255];
		int total = Action_GetTimeDb(client)+RoundFloat(GetClientTime(client)/60);
		Format(buffer, 255, "UPDATE `stats` SET `InGameTime` = '%i' WHERE `id` = '%i'",total, GetId(client));
		if (!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("[savetime]Failed to query (error: %s)", error);
			delete db;
			return false;
		}
		delete db;
		return true;
	}
	
}

public int Native_CreateDb(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	if(db == null)
	{
		PrintToServer("STATSdb not connect: %s", error);
	}
	else
	{
		char buffer[512];
		Format(buffer, 512, "INSERT INTO `stats` (`counter`, `id`, `name`, `InGameTime`, `stat1`,`stat2`,`stat3`,`stat4`) VALUES (NULL, '%i', '%N', '0', 0,0,0,0)", GetId(client), client);
		if (!SQL_FastQuery(db, buffer))
		{
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		LogMessage("[DB][Event_PlayerSpawn] Новый игрок %N занесен в базу данных статистики", client);
		LogMessage(buffer);		
	}
	delete db;
}

public int Native_IsDbCreated(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	
	char buffer[512];
	Format(buffer, 512, "SELECT `id` FROM `stats` WHERE `id` = '%i'", GetId(client));
	DBResultSet query = SQL_Query(db, buffer);
	if (query == null)
 	{
		PrintToServer("query = null, error: %s",buffer);
  	}
	else 
	{
		if (SQL_GetRowCount(query) == 0)
		{
			delete query;
			delete db;
			return false;
		}
		else
		{
			delete query;
			delete db;
			return true;
		}
	}
	delete query;
	delete db;
}



public int Native_ShowTime(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	int result = RoundFloat(GetClientTime(client)/60);
	return result;
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
					int temp_int;
					temp_int = SQL_FetchInt(query, 0);
					delete query;
					delete db;
					return temp_int;
				}	
				delete query;
			}
		}
		delete db;
		return -1;
	}
	delete db;
	return -1;
}

bool IsClientValid(int client)
{
	return ((client > 0) && (client <= MaxClients) && IsClientInGame(client));
}

int Action_GetTimeDb(int client)
{
	char error[255];
	Database db = SQL_DefConnect(error, sizeof(error));
	if(db == null)
	{
		PrintToServer("[GetTimeDB]Could not connect to db: %s", error);
	}
	else
	{
		char buffer[255];
		FormatEx(buffer, sizeof(buffer), "SELECT `InGameTime` FROM `stats` WHERE `id` = '%i'", GetId(client));
		DBResultSet query = SQL_Query(db, buffer);
		if (query == null)
		{
			PrintToServer("SQL Query errored (GetTimeDb(%d))", client);
		}
		else
		{
			while (SQL_FetchRow(query))
			{
				int temp_int;
				temp_int = SQL_FetchInt(query, 0);
				delete query;
				delete db;
				return temp_int;
			}	
			delete query;
		}
	}
	delete db;
}