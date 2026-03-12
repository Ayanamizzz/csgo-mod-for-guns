#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "Team Gun Menu Save",
    author = "Beifeng",
    description = "CT/T loadout menu with saved preferences",
    version = "2.0",
    url = ""
};

enum CTPrimaryChoice
{
    CTPrimary_M4A4 = 0,
    CTPrimary_M4A1S,
    CTPrimary_AUG,
    CTPrimary_FAMAS,
    CTPrimary_AWP
};

enum CTSecondaryChoice
{
    CTSecondary_USP = 0,
    CTSecondary_P2000,
    CTSecondary_FIVESEVEN,
    CTSecondary_Deagle
};

enum TPrimaryChoice
{
    TPrimary_AK47 = 0,
    TPrimary_GALIL,
    TPrimary_SG553,
    TPrimary_AWP
};

enum TSecondaryChoice
{
    TSecondary_GLOCK = 0,
    TSecondary_P250,
    TSecondary_TEC9
};

int g_iCTPrimary[MAXPLAYERS + 1];
int g_iCTSecondary[MAXPLAYERS + 1];
int g_iTPrimary[MAXPLAYERS + 1];
int g_iTSecondary[MAXPLAYERS + 1];

Cookie g_hCTPrimaryCookie;
Cookie g_hCTSecondaryCookie;
Cookie g_hTPrimaryCookie;
Cookie g_hTSecondaryCookie;

public void OnPluginStart()
{
    RegConsoleCmd("sm_guns", Command_Guns, "Open team gun menu");
    RegConsoleCmd("sm_gun", Command_Guns, "Open team gun menu");

    HookEvent("player_spawn", Event_PlayerSpawn);

    g_hCTPrimaryCookie   = RegClientCookie("gunmenu_ct_primary",   "CT primary weapon choice",   CookieAccess_Private);
    g_hCTSecondaryCookie = RegClientCookie("gunmenu_ct_secondary", "CT secondary weapon choice", CookieAccess_Private);
    g_hTPrimaryCookie    = RegClientCookie("gunmenu_t_primary",    "T primary weapon choice",    CookieAccess_Private);
    g_hTSecondaryCookie  = RegClientCookie("gunmenu_t_secondary",  "T secondary weapon choice",  CookieAccess_Private);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            ResetClientDefaults(i);

            if (!IsFakeClient(i) && AreClientCookiesCached(i))
            {
                LoadClientCookies(i);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    ResetClientDefaults(client);

    if (!IsFakeClient(client) && AreClientCookiesCached(client))
    {
        LoadClientCookies(client);
    }
}

public void OnClientCookiesCached(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client))
    {
        return;
    }

    LoadClientCookies(client);
}

public Action Command_Guns(int client, int args)
{
    if (!IsValidClient(client))
    {
        return Plugin_Handled;
    }

    ShowRootMenu(client);
    return Plugin_Handled;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidAliveClient(client))
    {
        return;
    }

    if (GetClientTeam(client) != CS_TEAM_CT && GetClientTeam(client) != CS_TEAM_T)
    {
        return;
    }

    CreateTimer(0.2, Timer_ApplyLoadout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_ApplyLoadout(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (!IsValidAliveClient(client))
    {
        return Plugin_Stop;
    }

    ApplyLoadout(client);
    return Plugin_Stop;
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsValidAliveClient(int client)
{
    return IsValidClient(client) && IsPlayerAlive(client);
}

void ResetClientDefaults(int client)
{
    g_iCTPrimary[client] = CTPrimary_M4A4;
    g_iCTSecondary[client] = CTSecondary_USP;

    g_iTPrimary[client] = TPrimary_AK47;
    g_iTSecondary[client] = TSecondary_GLOCK;
}

void LoadClientCookies(int client)
{
    char value[16];

    GetClientCookie(client, g_hCTPrimaryCookie, value, sizeof(value));
    if (value[0] != '\0')
    {
        int n = StringToInt(value);
        if (n >= CTPrimary_M4A4 && n <= CTPrimary_AWP)
        {
            g_iCTPrimary[client] = n;
        }
    }

    GetClientCookie(client, g_hCTSecondaryCookie, value, sizeof(value));
    if (value[0] != '\0')
    {
        int n = StringToInt(value);
        if (n >= CTSecondary_USP && n <= CTSecondary_Deagle)
        {
            g_iCTSecondary[client] = n;
        }
    }

    GetClientCookie(client, g_hTPrimaryCookie, value, sizeof(value));
    if (value[0] != '\0')
    {
        int n = StringToInt(value);
        if (n >= TPrimary_AK47 && n <= TPrimary_AWP)
        {
            g_iTPrimary[client] = n;
        }
    }

    GetClientCookie(client, g_hTSecondaryCookie, value, sizeof(value));
    if (value[0] != '\0')
    {
        int n = StringToInt(value);
        if (n >= TSecondary_GLOCK && n <= TSecondary_TEC9)
        {
            g_iTSecondary[client] = n;
        }
    }
}

void SaveClientCookies(int client)
{
    if (!IsValidClient(client) || IsFakeClient(client) || !AreClientCookiesCached(client))
    {
        return;
    }

    char value[16];

    IntToString(g_iCTPrimary[client], value, sizeof(value));
    SetClientCookie(client, g_hCTPrimaryCookie, value);

    IntToString(g_iCTSecondary[client], value, sizeof(value));
    SetClientCookie(client, g_hCTSecondaryCookie, value);

    IntToString(g_iTPrimary[client], value, sizeof(value));
    SetClientCookie(client, g_hTPrimaryCookie, value);

    IntToString(g_iTSecondary[client], value, sizeof(value));
    SetClientCookie(client, g_hTSecondaryCookie, value);
}

void ShowRootMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Root);
    menu.SetTitle("枪械菜单");

    menu.AddItem("ct", "设置 CT 武器");
    menu.AddItem("t", "设置 T 武器");
    menu.AddItem("apply", "立即应用当前阵营配置");

    menu.ExitButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_Root(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "ct"))
        {
            ShowCTMenu(client);
        }
        else if (StrEqual(info, "t"))
        {
            ShowTMenu(client);
        }
        else if (StrEqual(info, "apply"))
        {
            if (IsValidAliveClient(client))
            {
                ApplyLoadout(client);
                PrintToChat(client, "\x04[GunMenu]\x01 已应用你当前阵营的武器配置。");
            }
            else
            {
                PrintToChat(client, "\x04[GunMenu]\x01 你现在不存活，配置会在下次重生时自动应用。");
            }

            ShowRootMenu(client);
        }
    }

    return 0;
}

void ShowCTMenu(int client)
{
    Menu menu = new Menu(MenuHandler_CTMenu);
    menu.SetTitle("CT 配置");

    char line[128];
    char weaponName[64];

    GetCTPrimaryName(g_iCTPrimary[client], weaponName, sizeof(weaponName));
    Format(line, sizeof(line), "主武器: %s", weaponName);
    menu.AddItem("primary", line);

    GetCTSecondaryName(g_iCTSecondary[client], weaponName, sizeof(weaponName));
    Format(line, sizeof(line), "副武器: %s", weaponName);
    menu.AddItem("secondary", line);

    menu.AddItem("apply", "立即应用 CT 配置");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_CTMenu(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowRootMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "primary"))
        {
            ShowCTPrimaryMenu(client);
        }
        else if (StrEqual(info, "secondary"))
        {
            ShowCTSecondaryMenu(client);
        }
        else if (StrEqual(info, "apply"))
        {
            if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_CT)
            {
                ApplyLoadout(client);
                PrintToChat(client, "\x04[GunMenu]\x01 已应用 CT 配置。");
            }
            else
            {
                PrintToChat(client, "\x04[GunMenu]\x01 CT 配置已保存，下次作为 CT 重生时自动应用。");
            }

            ShowCTMenu(client);
        }
    }

    return 0;
}

void ShowTMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TMenu);
    menu.SetTitle("T 配置");

    char line[128];
    char weaponName[64];

    GetTPrimaryName(g_iTPrimary[client], weaponName, sizeof(weaponName));
    Format(line, sizeof(line), "主武器: %s", weaponName);
    menu.AddItem("primary", line);

    GetTSecondaryName(g_iTSecondary[client], weaponName, sizeof(weaponName));
    Format(line, sizeof(line), "副武器: %s", weaponName);
    menu.AddItem("secondary", line);

    menu.AddItem("apply", "立即应用 T 配置");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_TMenu(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowRootMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "primary"))
        {
            ShowTPrimaryMenu(client);
        }
        else if (StrEqual(info, "secondary"))
        {
            ShowTSecondaryMenu(client);
        }
        else if (StrEqual(info, "apply"))
        {
            if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_T)
            {
                ApplyLoadout(client);
                PrintToChat(client, "\x04[GunMenu]\x01 已应用 T 配置。");
            }
            else
            {
                PrintToChat(client, "\x04[GunMenu]\x01 T 配置已保存，下次作为 T 重生时自动应用。");
            }

            ShowTMenu(client);
        }
    }

    return 0;
}

void ShowCTPrimaryMenu(int client)
{
    Menu menu = new Menu(MenuHandler_CTPrimary);
    menu.SetTitle("选择 CT 主武器");

    menu.AddItem("m4a4", "M4A4");
    menu.AddItem("m4a1s", "M4A1-S");
    menu.AddItem("aug", "AUG");
    menu.AddItem("famas", "FAMAS");
    menu.AddItem("awp", "AWP");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_CTPrimary(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowCTMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "m4a4"))
        {
            g_iCTPrimary[client] = CTPrimary_M4A4;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 主武器已设置为 M4A4。");
        }
        else if (StrEqual(info, "m4a1s"))
        {
            g_iCTPrimary[client] = CTPrimary_M4A1S;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 主武器已设置为 M4A1-S。");
        }
        else if (StrEqual(info, "aug"))
        {
            g_iCTPrimary[client] = CTPrimary_AUG;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 主武器已设置为 AUG。");
        }
        else if (StrEqual(info, "famas"))
        {
            g_iCTPrimary[client] = CTPrimary_FAMAS;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 主武器已设置为 FAMAS。");
        }
        else if (StrEqual(info, "awp"))
        {
            g_iCTPrimary[client] = CTPrimary_AWP;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 主武器已设置为 AWP。");
        }

        SaveClientCookies(client);

        if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_CT)
        {
            ApplyLoadout(client);
        }

        ShowCTMenu(client);
    }

    return 0;
}

void ShowCTSecondaryMenu(int client)
{
    Menu menu = new Menu(MenuHandler_CTSecondary);
    menu.SetTitle("选择 CT 副武器");

    menu.AddItem("usp", "USP-S");
    menu.AddItem("p2000", "P2000");
    menu.AddItem("57", "Five-SeveN");
    menu.AddItem("deagle", "Desert Eagle");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_CTSecondary(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowCTMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "usp"))
        {
            g_iCTSecondary[client] = CTSecondary_USP;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 副武器已设置为 USP-S。");
        }
        else if (StrEqual(info, "p2000"))
        {
            g_iCTSecondary[client] = CTSecondary_P2000;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 副武器已设置为 P2000。");
        }
        else if (StrEqual(info, "57"))
        {
            g_iCTSecondary[client] = CTSecondary_FIVESEVEN;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 副武器已设置为 Five-SeveN。");
        }
        else if (StrEqual(info, "deagle"))
        {
            g_iCTSecondary[client] = CTSecondary_Deagle;
            PrintToChat(client, "\x04[GunMenu]\x01 CT 副武器已设置为 Desert Eagle。");
        }

        SaveClientCookies(client);

        if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_CT)
        {
            ApplyLoadout(client);
        }

        ShowCTMenu(client);
    }

    return 0;
}

void ShowTPrimaryMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TPrimary);
    menu.SetTitle("选择 T 主武器");

    menu.AddItem("ak47", "AK-47");
    menu.AddItem("galil", "Galil AR");
    menu.AddItem("sg553", "SG 553");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_TPrimary(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowTMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "ak47"))
        {
            g_iTPrimary[client] = TPrimary_AK47;
            PrintToChat(client, "\x04[GunMenu]\x01 T 主武器已设置为 AK-47。");
        }
        else if (StrEqual(info, "galil"))
        {
            g_iTPrimary[client] = TPrimary_GALIL;
            PrintToChat(client, "\x04[GunMenu]\x01 T 主武器已设置为 Galil AR。");
        }
        else if (StrEqual(info, "sg553"))
        {
            g_iTPrimary[client] = TPrimary_SG553;
            PrintToChat(client, "\x04[GunMenu]\x01 T 主武器已设置为 SG 553。");
        }
        else if (StrEqual(info, "awp"))
        {
            g_iTPrimary[client] = TPrimary_AWP;
            PrintToChat(client, "\x04[GunMenu]\x01 T 主武器已设置为 AWP。");
        }

        SaveClientCookies(client);

        if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_T)
        {
            ApplyLoadout(client);
        }

        ShowTMenu(client);
    }

    return 0;
}

void ShowTSecondaryMenu(int client)
{
    Menu menu = new Menu(MenuHandler_TSecondary);
    menu.SetTitle("选择 T 副武器");

    menu.AddItem("glock", "Glock");
    menu.AddItem("p250", "P250");
    menu.AddItem("tec9", "Tec-9");

    menu.ExitBackButton = true;
    menu.Display(client, 20);
}

public int MenuHandler_TSecondary(Menu menu, MenuAction action, int client, int item)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_Cancel)
    {
        if (item == MenuCancel_ExitBack && IsValidClient(client))
        {
            ShowTMenu(client);
        }
    }
    else if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(item, info, sizeof(info));

        if (StrEqual(info, "glock"))
        {
            g_iTSecondary[client] = TSecondary_GLOCK;
            PrintToChat(client, "\x04[GunMenu]\x01 T 副武器已设置为 Glock。");
        }
        else if (StrEqual(info, "p250"))
        {
            g_iTSecondary[client] = TSecondary_P250;
            PrintToChat(client, "\x04[GunMenu]\x01 T 副武器已设置为 P250。");
        }
        else if (StrEqual(info, "tec9"))
        {
            g_iTSecondary[client] = TSecondary_TEC9;
            PrintToChat(client, "\x04[GunMenu]\x01 T 副武器已设置为 Tec-9。");
        }

        SaveClientCookies(client);

        if (IsValidAliveClient(client) && GetClientTeam(client) == CS_TEAM_T)
        {
            ApplyLoadout(client);
        }

        ShowTMenu(client);
    }

    return 0;
}

void ApplyLoadout(int client)
{
    int team = GetClientTeam(client);

    if (team == CS_TEAM_CT)
    {
        ApplyCTLoadout(client);
    }
    else if (team == CS_TEAM_T)
    {
        ApplyTLoadout(client);
    }
}

void ApplyCTLoadout(int client)
{
    RemoveWeaponBySlot(client, 0);
    RemoveWeaponBySlot(client, 1);

    switch (g_iCTPrimary[client])
    {
        case CTPrimary_M4A4:
        {
            GiveAndEquip(client, "weapon_m4a1");
        }
        case CTPrimary_M4A1S:
        {
            GiveAndEquip(client, "weapon_m4a1_silencer");
        }
        case CTPrimary_AUG:
        {
            GiveAndEquip(client, "weapon_aug");
        }
        case CTPrimary_FAMAS:
        {
            GiveAndEquip(client, "weapon_famas");
        }
        case CTPrimary_AWP:
        {
            GiveAndEquip(client, "weapon_awp");
        }
    }

    switch (g_iCTSecondary[client])
    {
        case CTSecondary_USP:
        {
            GiveAndEquip(client, "weapon_usp_silencer");
        }
        case CTSecondary_P2000:
        {
            GiveAndEquip(client, "weapon_hkp2000");
        }
        case CTSecondary_FIVESEVEN:
        {
            GiveAndEquip(client, "weapon_fiveseven");
        }
        case CTSecondary_Deagle:
        {
            GiveAndEquip(client, "weapon_deagle");
        }
    }
}

void ApplyTLoadout(int client)
{
    RemoveWeaponBySlot(client, 0);
    RemoveWeaponBySlot(client, 1);

    switch (g_iTPrimary[client])
    {
        case TPrimary_AK47:
        {
            GiveAndEquip(client, "weapon_ak47");
        }
        case TPrimary_GALIL:
        {
            GiveAndEquip(client, "weapon_galilar");
        }
        case TPrimary_SG553:
        {
            GiveAndEquip(client, "weapon_sg556");
        }
    }

    switch (g_iTSecondary[client])
    {
        case TSecondary_GLOCK:
        {
            GiveAndEquip(client, "weapon_glock");
        }
        case TSecondary_P250:
        {
            GiveAndEquip(client, "weapon_p250");
        }
        case TSecondary_TEC9:
        {
            GiveAndEquip(client, "weapon_tec9");
        }
    }
}

void GiveAndEquip(int client, const char[] weapon)
{
    int ent = GivePlayerItem(client, weapon);

    if (ent != -1)
    {
        EquipPlayerWeapon(client, ent);
    }
}

void RemoveWeaponBySlot(int client, int slot)
{
    int weapon = GetPlayerWeaponSlot(client, slot);

    if (weapon != -1 && IsValidEntity(weapon))
    {
        RemovePlayerItem(client, weapon);
        AcceptEntityInput(weapon, "Kill");
    }
}

void GetCTPrimaryName(int choice, char[] buffer, int maxlen)
{
    switch (choice)
    {
        case CTPrimary_M4A1S: strcopy(buffer, maxlen, "M4A1-S");
        case CTPrimary_AUG: strcopy(buffer, maxlen, "AUG");
        case CTPrimary_FAMAS: strcopy(buffer, maxlen, "FAMAS");
        case CTPrimary_AWP: strcopy(buffer, maxlen, "AWP");
        default: strcopy(buffer, maxlen, "M4A4");
    }
}

void GetCTSecondaryName(int choice, char[] buffer, int maxlen)
{
    switch (choice)
    {
        case CTSecondary_P2000: strcopy(buffer, maxlen, "P2000");
        case CTSecondary_FIVESEVEN: strcopy(buffer, maxlen, "Five-SeveN");
        case CTSecondary_Deagle: strcopy(buffer, maxlen, "Desert Eagle");
        default: strcopy(buffer, maxlen, "USP-S");
    }
}


void GetTSecondaryName(int choice, char[] buffer, int maxlen)
{
    switch (choice)
    {
        case TSecondary_P250: strcopy(buffer, maxlen, "P250");
        case TSecondary_TEC9: strcopy(buffer, maxlen, "Tec-9");
        default: strcopy(buffer, maxlen, "Glock");
    }
}


void GetTPrimaryName(int choice, char[] buffer, int maxlen)
{
    switch (choice)
    {
        case TPrimary_GALIL: strcopy(buffer, maxlen, "Galil AR");
        case TPrimary_SG553: strcopy(buffer, maxlen, "SG 553");
        case TPrimary_AWP: strcopy(buffer, maxlen, "AWP");
        default: strcopy(buffer, maxlen, "AK-47");
    }
}

