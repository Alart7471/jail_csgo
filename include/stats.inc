#if defined _customstats_included_
  #endinput
#endif
#define _customstats_included_

native bool Stats_SaveTime(int client);
native bool Stats_CreateDb(int client);
native bool Stats_IsDbCreated(int client);
native int Stats_ShowTime(int client);