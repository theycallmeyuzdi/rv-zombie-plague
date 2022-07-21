/* ===============================================================================

	---------------------------------
	-*- [CS] Weapon Restrict: API -*-
	---------------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Counter-Strike Weapon Restrict Functions
//

#if defined _cs_weapon_restrict_api_inc
	#endinput
#endif
#define _cs_weapon_restrict_api_inc

#pragma reqlib cs_weapon_restrict_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib cs_weapon_restrict_api
#endif

/**
 * Sets/resets a player weapon restriction
 *
 * @param i_Client			Valid player ID
 * @param i_WeaponRestrict	Whether to restrict weapons
 * @param i_WeaponAllowed	Allowed weapons in bitsums
 * @param i_WeaponDefault	Allowed default weapon
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Allowed default weapon not in allowed weapon bitsum 
 */
native cs_player_weapon_restrict_set( i_Client, i_WeaponRestrict, i_WeaponAllowed = 0, i_WeaponDefault = 0 );

/**
 * Retrieves a player weapon restriction
 *
 * @param i_Client			Valid player ID
 * @param i_WeaponAllowed	Retrieves allowed weapons in bitsums
 * @param i_WeaponDefault	Retrieves allowed default weapon
 *
 * @return					True → if player has weapon restriction
 *							False → if player has no weapon restriction
 *							False + error → provided player ID is invalid
 */
native cs_player_weapon_restrict_get( i_Client, &i_WeaponAllowed = 0, &i_WeaponDefault = 0 );