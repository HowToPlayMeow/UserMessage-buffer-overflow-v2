#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

// this plugin pretty much just intercepts a couple of MvM usermessages and
// resends them over the reliable stream, because they can easily overflow the
// unreliable stream

public Plugin myinfo = {
    name        = "UserMessage buffer overflow v2",
    author      = "sigsegv, fixed HowToPlayMeow",
    description = "Fix for the 'Disconnect: Buffer overflow in net message' error",
    version     = "2.0",
    url         = "https://github.com/HowToPlayMeow/UserMessage-buffer-overflow-v2",
};

UserMsg ID_MVMLocalPlayerUpgradesClear = INVALID_MESSAGE_ID;
UserMsg ID_MVMLocalPlayerUpgradesValue = INVALID_MESSAGE_ID;

public void OnPluginStart()
{
    ID_MVMLocalPlayerUpgradesClear = GetUserMessageId("MVMLocalPlayerUpgradesClear");
    if (ID_MVMLocalPlayerUpgradesClear == INVALID_MESSAGE_ID) {
        SetFailState("Can't get UserMessage ID for MVMLocalPlayerUpgradesClear");
    }

    ID_MVMLocalPlayerUpgradesValue = GetUserMessageId("MVMLocalPlayerUpgradesValue");
    if (ID_MVMLocalPlayerUpgradesValue == INVALID_MESSAGE_ID) {
        SetFailState("Can't get UserMessage ID for MVMLocalPlayerUpgradesValue");
    }

    HookUserMessage(ID_MVMLocalPlayerUpgradesClear, UserMsgHook, true, UserMsgHookPost);
    HookUserMessage(ID_MVMLocalPlayerUpgradesValue, UserMsgHook, true, UserMsgHookPost);
}

bool      resend = false;
UserMsg   resend_id = INVALID_MESSAGE_ID;
ArrayList resend_data = null;
ArrayList resend_players = null;

public Action UserMsgHook(UserMsg msg_id, BfRead msg, int[] players, int playersNum, bool reliable, bool init)
{
    if (!reliable) {
        resend = true;
        resend_id = msg_id;
        
        if (resend_data == null) resend_data = new ArrayList();
        resend_data.Clear();
        while (msg.BytesLeft != 0) {
            resend_data.Push(msg.ReadByte());
        }
        
        if (resend_players == null) resend_players = new ArrayList();
        resend_players.Clear();
        for (int i = 0; i < playersNum; ++i) {
            resend_players.Push(players[i]);
        }
        
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

// -- safe client check helper ----
stock bool IsValidClient(int client)
{
    return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}
// --- End helper ---

// SM bug: the "sent" parameter is a lie
public void UserMsgHookPost(UserMsg msg_id, bool sent)
{
    if (resend) {
        int[] players = new int[resend_players.Length];

        // filter out non-in-game clients
        ArrayList validPlayers = new ArrayList();
        int validCount = 0;
        for (int i = 0; i < resend_players.Length; ++i) {
            int c = resend_players.Get(i);
            if (IsValidClient(c)) {
                validPlayers.Push(c);
                validCount++;
            }
        }

        // Fill original 'players' array
        for (int i2 = 0; i2 < validCount; ++i2) {
            players[i2] = validPlayers.Get(i2);
        }

        if (validCount > 0) {
            BfWrite newmsg = view_as<BfWrite>(StartMessageEx(resend_id, players, validCount, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
            if (newmsg != INVALID_HANDLE) {
                for (int i = 0; i < resend_data.Length; ++i) {
                    newmsg.WriteByte(resend_data.Get(i));
                }
                EndMessage();
            }
        }

        delete validPlayers; // cleanup memory
        resend = false;
    }
}
