/* ===============================================================================

	-------------------
	-*- [ZP] Tokens -*-
	-------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
// #include < hamsandwich >
#include < zp_core_const >
#include < zp_tokens_const >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
// #define is_user_valid_alive(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[ZP] Tokens";
new const g_szPluginVersion[ ] = ZP_VERSION_STR;
new const g_szPluginAuthor[ ] = ZP_AUTHOR;

enum _:MAX_FORWARDS
{
	FW_TOKENS_UPDATE_PRE = 0,
	FW_TOKENS_UPDATE_POST
};

new g_bIsConnected;
// new g_bIsAlive;

new g_iForward[ MAX_FORWARDS ];
new g_iForwardReturn;
new g_iTokens[ MAX_PLAYERS + 1 ][ MAX_TOKENS ];

public plugin_init( )
{
	register_plugin( g_szPluginName, g_szPluginVersion, g_szPluginAuthor );

	g_iForward[ FW_TOKENS_UPDATE_PRE ] = CreateMultiForward( "zp_fw_tokens_update_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
	g_iForward[ FW_TOKENS_UPDATE_POST ] = CreateMultiForward( "zp_fw_tokens_update_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );

	register_dictionary( "zp_tokens.txt" );

	// RegisterHam( Ham_Spawn, "player", "fwHamSpawnPost", true, true );
	// RegisterHam( Ham_Killed, "player", "fwHamKilledPost", true, true );
}

public plugin_natives( )
{
	register_library( "zp_tokens" );

	register_native( "zp_tokens_set", "_tokens_set" );
	register_native( "zp_tokens_get", "_tokens_get" );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	// bitsum_del( g_bIsAlive, i_Client );
}

/* public fwHamSpawnPost( i_Client )
{
	if( !is_user_alive( i_Client ) )
	{
		return;
	}

	bitsum_set( g_bIsAlive, i_Client );
} */

/* public fwHamKilledPost( i_Victim, i_Attacker )
{
	bitsum_del( g_bIsAlive, i_Victim );
} */

public _tokens_set( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	return ftTokensUpdate( i_Client, get_param( 2 ), get_param( 3 ), get_param( 4 ) );
}

public _tokens_get( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return ZP_OUT_OF_RANGE;
	}

	return g_iTokens[ i_Client ][ get_param( 2 ) ];
}

/* ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
} */

ftTokensUpdate( i_Client, i_Tokens, i_Amount, i_Force )
{
	if( !i_Force )
	{
		ExecuteForward( g_iForward[ FW_TOKENS_UPDATE_PRE ], g_iForwardReturn, i_Client, i_Tokens, i_Amount );

		if( g_iForwardReturn >= PLUGIN_HANDLED )
		{
			return false;
		}
	}

	g_iTokens[ i_Client ][ i_Tokens ] = i_Amount;

	ExecuteForward( g_iForward[ FW_TOKENS_UPDATE_POST ], g_iForwardReturn, i_Client, i_Tokens, i_Amount );

	return true;
}