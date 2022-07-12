/* ===============================================================================

	------------------------------
	-*- [ZP] Tokens: Constants -*-
	------------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

//
// Zombie Plague Functions
//

#if defined _zp_tokens_const_inc
	#endinput
#endif
#define _zp_tokens_const_inc

/**
 * Tokens
 */
enum
{
	ZP_TOKENS_BRONZE = 0,
	ZP_TOKENS_SILVER,
	ZP_TOKENS_GOLD,
	ZP_TOKENS_DIAMOND
};

#define MAX_TOKENS ( ZP_TOKENS_DIAMOND + 1 )