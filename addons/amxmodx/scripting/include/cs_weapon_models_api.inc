/* ===============================================================================

	-------------------------------
	-*- [CS] Weapon Models: API -*-
	-------------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Counter-Strike Weapon Models Functions
//

#if defined _cs_weapon_models_api_inc
	#endinput
#endif
#define _cs_weapon_models_api_inc

#pragma reqlib cs_weapon_models_api
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib cs_weapon_models_api
#endif

/**
 * Sets a player weapon p_model
 *
 * @param i_Client			Valid player ID
 * @param i_Weapon			Valid weapon ID
 * @param sz_PModel			Weapon p_model
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Weapon ID is invalid
 */
native cs_player_weapon_p_model_set( i_Client, i_Weapon, const sz_PModel[ ] );

/**
 * Resets a player weapon p_model
 *
 * @param i_Client			Valid player ID
 * @param i_Weapon			Valid weapon ID
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Weapon ID is invalid
 */
native cs_player_weapon_p_model_reset( i_Client, i_Weapon );

/**
 * Sets a player weapon v_model
 *
 * @param i_Client			Valid player ID
 * @param i_Weapon			Valid weapon ID
 * @param sz_VModel			Weapon v_model
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Weapon ID is invalid
 */
native cs_player_weapon_v_model_set( i_Client, i_Weapon, const sz_VModel[ ] );

/**
 * Resets a player weapon v_model
 *
 * @param i_Client			Valid player ID
 * @param i_Weapon			Valid weapon ID
 *
 * @return					True → success
 *							False + error →
 *								* Player ID is invalid
 *								* Weapon ID is invalid
 */
native cs_player_weapon_v_model_reset( i_Client, i_Weapon );