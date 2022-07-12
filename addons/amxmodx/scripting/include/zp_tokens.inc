/* ===============================================================================

	------------------------
	-*- [ZP] Tokens: API -*-
	------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Zombie Plague Functions
//

#if defined _zp_tokens_inc
	#endinput
#endif
#define _zp_tokens_inc

#pragma reqlib zp_tokens
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib zp_tokens
#endif

#include < zp_core_const >
#include < zp_tokens_const >

/**
 * Called before attempting to update a player tokens
 *
 * @param i_Client			Valid player ID
 * @param i_Tokens			Valid tokens ID
 * @param i_Amount			Quantity of tokens
 *
 * @return					PLUGIN_CONTINUE → allows tokens update
 *							PLUGIN_HANDLED → blocks tokens update
 */
forward zp_fw_tokens_update_pre( i_Client, i_Tokens, i_Amount );

/**
 * Called after a player tokens are updated
 *
 * @param i_Client			Valid player ID
 * @param i_Tokens			Valid tokens ID
 * @param i_Amount			Quantity of tokens
 *
 * @noreturn
 */
forward zp_fw_tokens_update_post( i_Client, i_Tokens, i_Amount );

/**
 * Sets a player tokens
 *
 * @param i_Client			Valid player ID
 * @param i_Tokens			Valid tokens ID
 * @param i_Amount			Quantity of tokens
 * @param i_Force			Whether to force token update
 *
 * @return					True → success
 *							False → failure
 *							False + error → player ID is invalid
 */
native zp_tokens_set( i_Client, i_Tokens, i_Amount, i_Force = 0 );

/**
 * Returns a player tokens
 *
 * @param i_Client			Valid player ID
 * @param i_Tokens			Valid tokens ID
 *
 * @return					Quantity of specified tokens → success
 *							ZP_OUT_OF_RANGE + error → player ID is invalid
 */
native zp_tokens_get( i_Client, i_Tokens );