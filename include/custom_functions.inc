//custom_functions.inc

#if defined _myfucn_included_
  #endinput
#endif
#define _myfucn_included_

native int Alart_GetId(int client);
native int Alart_GetAdminStatus(int client);
native int Alart_GetAdminPriority(char[] rank);
