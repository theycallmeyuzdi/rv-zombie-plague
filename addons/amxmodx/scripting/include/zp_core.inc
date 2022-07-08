/* ===============================================================================

	----------------------
	-*- [ZP] Core: API -*-
	----------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Zombie Plague Functions
//

#if defined _zp_core_inc
	#endinput
#endif
#define _zp_core_inc

#pragma reqlib zp_core
#if !defined AMXMODX_NOAUTOLOAD
	#pragma loadlib zp_core
#endif

#include < zp_core_const >

/**
 * Called after a player spawns
 *
 * @note This is called after a player spawns, and
 *		 before updating Zombie/Human bitsums
 *
 * @param i_Client			Valid player ID
 *
 * @noreturn
 */
forward zp_fw_core_spawn_post( i_Client );

/**
 * Called before attempting to infect a player
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether infection is forced
 *
 * @return					PLUGIN_CONTINUE → allows infection
 *							PLUGIN_HANDLED → blocks infection
 */
forward zp_fw_core_infect_pre( i_Client, i_Attacker, i_Force );

/**
 * Called before a player is infected
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether infection is forced
 *
 * @noreturn
 */
forward zp_fw_core_infect( i_Client, i_Attacker, i_Force );

/**
 * Called after a player is infected
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether infection is forced
 *
 * @noreturn
 */
forward zp_fw_core_infect_post( i_Client, i_Attacker, i_Force );

/**
 * Called before attempting to cure a player
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether cure is forced
 *
 * @return					PLUGIN_CONTINUE → allows cure
 *							PLUGIN_HANDLED → blocks cure
 */
forward zp_fw_core_cure_pre( i_Client, i_Attacker, i_Force );

/**
 * Called before a player is cured
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether cure is forced
 *
 * @noreturn
 */
forward zp_fw_core_cure( i_Client, i_Attacker, i_Force );

/**
 * Called after a player is cured
 *
 * @param i_Client			Valid player ID
 * @param i_Attacker		Valid player ID
 * @param i_Force			Whether cured is forced
 *
 * @noreturn
 */
forward zp_fw_core_cure_post( i_Client, i_Attacker, i_Force );

/**
 * Called after a player becomes the Last Zombie
 *
 * @param i_Client			Valid player ID
 *
 * @noreturn
 */
forward zp_fw_core_last_zombie( i_Client );

/**
 * Called after a player becomes the Last Human
 *
 * @param i_Client			Valid player ID
 *
 * @noreturn
 */
forward zp_fw_core_last_human( i_Client );

/**
 * Sets or removes Respawn As Zombie
 *
 * @param i_Client			Valid player ID
 * @param i_RespawnAsZombie	Whether to set Respawn As Zombie
 *
 * @return					True → success
 *							False + error → provided player ID is invalid
 */
native zp_core_respawn_as_zombie( i_Client, i_RespawnAsZombie );

/**
 * Turns a player into Zombie
 *
 * @param i_Client			Valid player ID (must be alive)
 * @param i_Attacker		Valid player ID (must be connected)
 * @param i_Force			Whether to force infection
 *
 * @return					True → success
 *							False → failure
 *							False + error →
 *								* Player ID is invalid (i_Client or i_Attacker)
 *								* Attempting to infect a Zombie without force
 */
native zp_core_infect( i_Client, i_Attacker = 0, i_Force = 0 );

/**
 * Turns a player into Human
 *
 * @param i_Client			Valid player ID (must be alive)
 * @param i_Attacker		Valid player ID (must be connected)
 * @param i_Force			Whether to force cure
 *
 * @return					True → success
 *							False → failure
 *							False + error →
 *								* Player ID is invalid (i_Client or i_Attacker)
 *								* Attempting to cure a Human without force
 */
native zp_core_cure( i_Client, i_Attacker = 0, i_Force = 0 );

/**
 * Checks whether a player is Zombie
 *
 * @param i_Client			Valid player ID
 *
 * @return					i_Client → player is Zombie
 *							0 → player is not Zombie
 *							ZP_OUT_OF_RANGE + error → player ID is invalid
 */
native zp_core_is_zombie( i_Client );

/**
 * Checks whether a player is First Zombie
 *
 * @param i_Client			Valid player ID
 *
 * @return					i_Client → player is First Zombie
 *							0 → player is not First Zombie
 *							ZP_OUT_OF_RANGE + error → player ID is invalid
 */
native zp_core_is_first_zombie( i_Client );

/**
 * Checks whether a player is Last Zombie
 *
 * @param i_Client			Valid player ID
 *
 * @return					i_Client → player is Last Zombie
 *							0 → player is not Last Zombie
 *							ZP_OUT_OF_RANGE + error → player ID is invalid
 */
native zp_core_is_last_zombie( i_Client );

/**
 * Checks whether a player is Last Zombie
 *
 * @param i_Client			Valid player ID
 *
 * @return					i_Client → player is Last Zombie
 *							0 → player is not Last Zombie
 *							ZP_OUT_OF_RANGE + error → player ID is invalid
 */
native zp_core_is_last_human( i_Client );

/**
 * Returns the count of alive Zombies
 *
 * @return					Returns the count of alive Zombies
 */
native zp_core_get_count_zombie( );

/**
 * Returns the count of alive Humans
 *
 * @return					Returns the count of alive Humans
 */
native zp_core_get_count_human( );