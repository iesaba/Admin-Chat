#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define MESS "[iesaba] %s"
#define PLUGIN_VERSION "1.2"

new Handle:deathrun_manager_version = INVALID_HANDLE;
new Handle:deathrun_enabled         = INVALID_HANDLE;
new Handle:deathrun_swapteam        = INVALID_HANDLE;
new Handle:deathrun_block_suicide   = INVALID_HANDLE;
new Handle:deathrun_fall_damage     = INVALID_HANDLE;
new Handle:deathrun_limit_terror    = INVALID_HANDLE;

public Plugin:myinfo =
{
	name        = "Deathrun Manager",
	author      = "Rogue",
	description = "Manages terrorists/counter-terrorists on DR servers",
	version     = PLUGIN_VERSION,
	url         = "http://www.surf-infamous.com/"
};

public OnPluginStart()
{
	AddCommandListener(BlockKill, "kill");
	AddCommandListener(BlockSpec, "spectate");
	AddCommandListener(Cmd_JoinTeam, "jointeam");

	HookEvent("player_connect_full", Event_OnFullConnect, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);

	deathrun_manager_version = CreateConVar("deathrun_manager_version", PLUGIN_VERSION, "Deathrun Manager version; not changeable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	deathrun_enabled         = CreateConVar("deathrun_enabled", "1", "Enable or disable Deathrun Manager; 0 - disabled, 1 - enabled");
	deathrun_swapteam        = CreateConVar("deathrun_swapteam", "1", "Enable or disable automatic swapping of CTs and Ts; 1 - enabled, 0 - disabled");
	deathrun_block_suicide   = CreateConVar("deathrun_block_suicide", "1", "Block or allow the 'kill' command; 1 - command is blocked, 0 - command is allowed");
	deathrun_fall_damage     = CreateConVar("deathrun_fall_damage", "1", "Blocks fall damage given to terrorists; 1 - enabled, 0 - disabled");
	deathrun_limit_terror    = CreateConVar("deathrun_limit_terror", "0", "Limits terrorist team to chosen value; 0 - disabled");

	SetConVarString(deathrun_manager_version, PLUGIN_VERSION);
	AutoExecConfig(true, "deathrun_manager");
}

public OnConfigsExecuted()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));

	if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0))
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Manager.");
		SetConVarInt(deathrun_enabled, 1);
	}
	else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Manager.");
		SetConVarInt(deathrun_enabled, 0);
	}
}

public IsValidClient(client)
{
	if (client == 0)
		return false;

	if (!IsClientConnected(client))
		return false;

	if (IsFakeClient(client))
		return false;

	if (!IsClientInGame(client))
		return false;

	return true;
}

public Action:Event_OnFullConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	new Terrorist;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		new Team = GetClientTeam(i);
		if(Team == CS_TEAM_T)
			Terrorist++;
	}

	if(Terrorist <= 0)
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
	else
		SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);

	ForcePlayerSuicide(client);
	//CS_RespawnPlayer(client);

	return Plugin_Continue;
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_swapteam) == 1) && (GetClientTeam(client) == CS_TEAM_T))
	{
		//moveter(client);
		CS_SwitchTeam(client, CS_TEAM_CT);
		PrintToChat(client, MESS, "You have died and have been moved to Counter-Terrorists");
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_swapteam) == 1))
	{
		for (new i = 1; i < MaxClients; i++)
		{
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T)
			{
				CS_SwitchTeam(i, CS_TEAM_CT);
				//movect(GetRandomPlayer(CS_TEAM_CT));
				new counter = GetRandomPlayer(CS_TEAM_CT);
				if ((counter != -1) && (GetTeamClientCount(CS_TEAM_T) == 0))
				{
					CS_SwitchTeam(counter, CS_TEAM_T);
					PrintToChatAll(MESS, "A random player has been moved to Terrorist");
				}
			}
		}
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_fall_damage) == 1))
	{
		new ev_attacker = GetEventInt(event, "attacker");
		new ev_client = GetEventInt(event, "userid");
		new client = GetClientOfUserId(ev_client);

		if ((ev_attacker == 0) && (IsPlayerAlive(client)) && (GetClientTeam(client) == CS_TEAM_T))
			SetEntData(client, FindSendPropOffs("CBasePlayer", "m_iHealth"), 100);
	}
}

/*void:movect(client)
{
	CreateTimer(0.1, movectt, client);
}*/

/*void:moveter(client)
{
	CreateTimer(0.1, movet, client);
}*/

/*public Action:movectt(Handle:timer, any:client)
{
	new counter = GetRandomPlayer(CS_TEAM_CT);
	if ((counter != -1) && (GetTeamClientCount(CS_TEAM_T) == 0))
	{
		CS_SwitchTeam(counter, CS_TEAM_T);
		PrintToChatAll(MESS, "A random player has been moved to Terrorist");
	}
}*/

/*public Action:movet(Handle:timer, any:client)
{
	CS_SwitchTeam(client, CS_TEAM_CT);
	PrintToChat(client, MESS, "You have died and have been moved to Counter-Terrorists");
}*/

public Action:BlockKill(client, const String:command[], args)
{
	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_block_suicide) == 1))
	{
		PrintToChat(client, MESS, "Do not attempt to suicide to avoid death!");
		PrintToChat(client, MESS, "If you wish to join the spectator team, type 'spectate' into console");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:BlockSpec(client, const String:command[], args)
{
	return Plugin_Stop;
}

/*  For some reason hooking this command means that you can not use the 'jointeam' command via console.
    Not that it really matters anyway, because the command is hidden. Changing team VIA the GUI
    (pressing M) still works fine though. I know of a way to 'fix' it if it's a major problem for anybody. */ 
public Action:Cmd_JoinTeam(client, const String:command[], args)
{
	if (args == 0)
		return Plugin_Continue;

	new argg, String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	argg = StringToInt(arg);

	if (GetConVarInt(deathrun_enabled) == 1 && (GetConVarInt(deathrun_limit_terror) > 0) && (argg == 2))
	{
		new teamcount = GetTeamClientCount(CS_TEAM_T);

		if (teamcount >= GetConVarInt(deathrun_limit_terror))
		{
			PrintToChat(client, MESS, "There is already enough players on the Terrorist team!");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

GetRandomPlayer(team)
{
	new clients[MaxClients+1], clientCount;
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetClientTeam(i) == team))
		clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}
