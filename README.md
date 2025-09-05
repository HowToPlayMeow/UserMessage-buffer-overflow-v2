## sigsegv's, fixed HowToPlayMeow

### mvm-usermessage-overflow-fix-v2
- plugin fixes the **“Disconnect: Buffer overflow in net message”** issue in TF2’s Mann vs. Machine (MvM) mode.
- It works by intercepting specific MvM usermessages like **MVMLocalPlayerUpgradesClear** and **MVMLocalPlayerUpgradesValue**.
- Instead of letting them go through the unreliable channel **(which can overflow)**, it resends them through the reliable channel.
- This prevents crashes or disconnects when there’s too much upgrade data being sent.

Added IsClientInGame (fixes server crash bug)
original plugin had a bug that caused the server to crash because the client wasn't checked for presence. If the client left the server, the server would crash.

