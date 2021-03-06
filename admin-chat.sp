#include <sourcemod>
#include <cstrike>

#pragma semicolon 1

public Plugin:myinfo =
{
	name        = "AdminChatColor",
	author      = "k725",
	description = "Admin chat color.",
	version     = "1.0",
	url         = ""
}

public OnPluginStart()
{
	RegConsoleCmd("say", Say_Hook);
}

public Action:Say_Hook(client, args)
{
	decl String:sText[192];
	decl String:sDead[8];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);

	new Team = GetClientTeam(client);

	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		if(strlen(sText) > 0 && client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			sDead = IsPlayerAlive(client) ? "" : "*DEAD* ";
			
			if(Team == CS_TEAM_T)
				PrintToChatAll("[iesaba] %s\x09%N: \x05%s", sDead, client, sText);
			else if (Team == CS_TEAM_CT)
				PrintToChatAll("[iesaba] %s\x0d%N: \x05%s", sDead, client, sText);
			else
				PrintToChatAll("[iesaba] \x0e%N: \x05%s", client, sText);
		}
	}
	else
		return Plugin_Continue;

	return Plugin_Handled;
}
