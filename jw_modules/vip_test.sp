public Action Vip_OnPluginStart()
{
	CGOPrintToChatAll("Vip_OnPluginStart");
}

public Action Vip_Event_RoundStart()
{
	CGOPrintToChatAll("Vip_Event_RoundStart");
}

public Action Vip_Event_RoundEnd()
{
	CGOPrintToChatAll("Vip_Event_RoundEnd");
}

public Action Vip_Event_PlayerSpawn(int client)
{
	CGOPrintToChatAll("%N заспавнился", client);
}

public bool IsPlayerVip(int client)
{
	return false;
}