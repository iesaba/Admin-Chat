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
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);

	new AdminId:ID = GetUserAdmin(client);
	new Team       = GetClientTeam(client);

	if(ID != INVALID_ADMIN_ID)
	{
		if(client > 0 && client <= MaxClients && IsClientInGame(client))
		{
			if(Team == CS_TEAM_T)
				PrintToChatAll("[Admin] \x02%N: \x01%s", client, sText);
			else if (Team == CS_TEAM_CT)
				PrintToChatAll("[Admin] \x04%N: \x01%s", client, sText);
			else
				PrintToChatAll("[Admin] \x0e%N: \x01%s", client, sText);
		}
	}
	else
		return Plugin_Continue;

	return Plugin_Handled;
}
