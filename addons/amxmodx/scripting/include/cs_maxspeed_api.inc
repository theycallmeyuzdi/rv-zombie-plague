/* ===============================================================================

	--------------------------
	-*- [CS] Max Speed: API -*-
	--------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Counter-Strike Max Speed Functions
//

#if defined _cs_maxspeed_api_inc
	#endinput
#endif
#define _cs_maxspeed_api_inc

#pragma reqlib cs_maxspeed_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib cs_maxspeed_api
#endif

#include < cs_maxspeed_api_const >

/**
 * Sets a player custom maxspeed
 *
 * @param i_Client			Valid player ID
 * @param fl_MaxSpeed		Valid maxspeed value (> 0.0)
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Maxspeed value is invalid (< 0.0)
 */
native cs_player_maxspeed_set( i_Client, Float:fl_MaxSpeed );

/**
 * Resets a player custom maxspeed
 *
 * @param i_Client			Valid player ID
 *
 * @return					True → success
 *							False + error → player ID is invalid
 */
native cs_player_maxspeed_reset( i_Client );