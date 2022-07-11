/* ===============================================================================

	-----------------
	-*- [ZP] Core -*-
	-----------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
#include < hamsandwich >
#include < zp_core_const >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[ZP] Core";
new const g_szPluginVersion[ ] = ZP_VERSION_STR;
new const g_szPluginAuthor[ ] = ZP_AUTHOR;

enum _:MAX_FORWARDS
{
	FW_CORE_SPAWN_POST = 0,

	FW_CORE_INFECT_PRE,
	FW_CORE_INFECT,
	FW_CORE_INFECT_POST,

	FW_CORE_CURE_PRE,
	FW_CORE_CURE,
	FW_CORE_CURE_POST,

	FW_CORE_LAST_ZOMBIE,
	FW_CORE_LAST_HUMAN
};

new g_bIsConnected;
new g_bIsAlive;
new g_bRespawnAsZombie;
new g_bIsZombie;
new g_bIsFirstZombie;
new g_bIsLastZombie;
new g_bIsLastHuman;

new bool:g_bIsForwardCalledLastZombie;
new bool:g_bIsForwardCalledLastHuman;

new g_iForward[ MAX_FORWARDS ];
new g_iForwardReturn;

public plugin_init( )
{
	register_plugin( g_szPluginName, g_szPluginVersion, g_szPluginAuthor );

	g_iForward[ FW_CORE_SPAWN_POST ] = CreateMultiForward( "zp_fw_core_spawn_post", ET_IGNORE, FP_CELL );

	g_iForward[ FW_CORE_INFECT_PRE ] = CreateMultiForward( "zp_fw_core_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
	g_iForward[ FW_CORE_INFECT ] = CreateMultiForward( "zp_fw_core_infect", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );
	g_iForward[ FW_CORE_INFECT_POST ] = CreateMultiForward( "zp_fw_core_infect_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );

	g_iForward[ FW_CORE_CURE_PRE ] = CreateMultiForward( "zp_fw_core_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL );
	g_iForward[ FW_CORE_CURE ] = CreateMultiForward( "zp_fw_core_cure", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );
	g_iForward[ FW_CORE_CURE_POST ] = CreateMultiForward( "zp_fw_core_cure_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );

	g_iForward[ FW_CORE_LAST_ZOMBIE ] = CreateMultiForward( "zp_fw_core_last_zombie", ET_IGNORE, FP_CELL );
	g_iForward[ FW_CORE_LAST_HUMAN ] = CreateMultiForward( "zp_fw_core_last_human", ET_IGNORE, FP_CELL );

	RegisterHam( Ham_Spawn, "player", "fwHamSpawnPost", true, true );
	RegisterHam( Ham_Killed, "player", "fwHamKilledPost", true, true );
}

public plugin_natives( )
{
	register_library( "zp_core" );

	register_native( "zp_core_respawn_as_zombie", "_core_respawn_as_zombie" );
	register_native( "zp_core_infect", "_core_infect" );
	register_native( "zp_core_cure", "_core_cure" );
	register_native( "zp_core_is_zombie", "_core_is_zombie" );
	register_native( "zp_core_is_first_zombie", "_core_is_first_zombie" );
	register_native( "zp_core_is_last_zombie", "_core_is_last_zombie" );
	register_native( "zp_core_is_last_human", "_core_is_last_human" );
	register_native( "zp_core_get_count_zombie", "_core_get_count_zombie" );
	register_native( "zp_core_get_count_human", "_core_get_count_human" );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	bitsum_del( g_bIsAlive, i_Client );
	bitsum_del( g_bRespawnAsZombie, i_Client );
	bitsum_del( g_bIsZombie, i_Client );
	bitsum_del( g_bIsFirstZombie, i_Client );
	bitsum_del( g_bIsLastZombie, i_Client );
	bitsum_del( g_bIsLastHuman, i_Client );

	ftLastPlayerUpdate( );
}

public fwHamSpawnPost( i_Client )
{
	if( !is_user_alive( i_Client ) )
	{
		return;
	}

	bitsum_set( g_bIsAlive, i_Client );

	ExecuteForward( g_iForward[ FW_CORE_SPAWN_POST ], g_iForwardReturn, i_Client );

	if( bitsum_get( g_bRespawnAsZombie, i_Client ) )
	{
		ftPlayerInfect( i_Client, i_Client );
	}
	else
	{
		ftPlayerCure( i_Client );
	}

	bitsum_del( g_bRespawnAsZombie, i_Client );
}

public fwHamKilledPost( i_Victim /* , i_Attacker */ )
{
	bitsum_del( g_bIsAlive, i_Victim );

	ftLastPlayerUpdate( );
}

public _core_respawn_as_zombie( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	new i_RespawnAsZombie = get_param( 2 );

	if( i_RespawnAsZombie )
	{
		bitsum_set( g_bRespawnAsZombie, i_Client );
	}
	else
	{
		bitsum_del( g_bRespawnAsZombie, i_Client );
	}

	return true;
}

public _core_infect( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Force = get_param( 3 );

	if( !is_user_valid_alive( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not alive (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	if( !i_Force && bitsum_get( g_bIsZombie, i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is already infected (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	new i_Attacker = get_param( 2 );

	if( i_Attacker && !is_user_valid_connected( i_Attacker ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Attacker );

		return false;
	}

	return ftPlayerInfect( i_Client, i_Attacker, i_Force );
}

public _core_cure( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Force = get_param( 3 );

	if( !is_user_valid_alive( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not alive (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	if( !i_Force && !bitsum_get( g_bIsZombie, i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is already cured (%d)", ZP_PREFIX, i_Client );

		return false;
	}

	new i_Attacker = get_param( 2 );

	if( i_Attacker && !is_user_valid_connected( i_Attacker ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Attacker );

		return false;
	}

	return ftPlayerCure( i_Client, i_Attacker, i_Force );
}

public _core_is_zombie( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Return = get_param( 2 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return i_Return ? ZP_OUT_OF_RANGE : 0;
	}

	return bitsum_get( g_bIsZombie, i_Client ) ? ( i_Return ? i_Client : 1 ) : 0;
}

public _core_is_first_zombie( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Return = get_param( 2 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return i_Return ? ZP_OUT_OF_RANGE : 0;
	}

	return bitsum_get( g_bIsFirstZombie, i_Client ) ? ( i_Return ? i_Client : 1 ) : 0;
}

public _core_is_last_zombie( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Return = get_param( 2 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return i_Return ? ZP_OUT_OF_RANGE : 0;
	}

	return bitsum_get( g_bIsLastZombie, i_Client ) ? ( i_Return ? i_Client : 1 ) : 0;
}

public _core_is_last_human( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 ), i_Return = get_param( 2 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Player is not in-game (%d)", ZP_PREFIX, i_Client );

		return i_Return ? ZP_OUT_OF_RANGE : 0;
	}

	return bitsum_get( g_bIsLastHuman, i_Client ) ? ( i_Return ? i_Client : 1 ) : 0;
}

public _core_get_count_zombie( /* i_Plugin, i_Parameter */ )
{
	return ftGetCountZombie( );
}

public _core_get_count_human( /* i_Plugin, i_Parameter */ )
{
	return ftGetCountHuman( );
}

ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
}

ftGetCountZombie( )
{
	return ftGetCountBitsum( g_bIsAlive & g_bIsZombie );
}

ftGetCountHuman( )
{
	return ftGetCountBitsum( g_bIsAlive ) - ftGetCountZombie( );
}

ftPlayerInfect( i_Client, i_Attacker = 0, i_Force = 0 )
{
	ExecuteForward( g_iForward[ FW_CORE_INFECT_PRE ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	if( g_iForwardReturn >= PLUGIN_HANDLED )
	{
		return false;
	}
	
	ExecuteForward( g_iForward[ FW_CORE_INFECT ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	bitsum_set( g_bIsZombie, i_Client );

	bitsum_del( g_bIsFirstZombie, i_Client );
	bitsum_del( g_bIsLastZombie, i_Client );
	bitsum_del( g_bIsLastHuman, i_Client );

	if( ftGetCountZombie( ) == 1 )
	{
		bitsum_set( g_bIsFirstZombie, i_Client );
	}
	else
	{
		bitsum_del( g_bIsFirstZombie, i_Client );
	}

	ExecuteForward( g_iForward[ FW_CORE_INFECT_POST ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	ftLastPlayerUpdate( );

	return true;
}

ftPlayerCure( i_Client, i_Attacker = 0, i_Force = 0 )
{
	ExecuteForward( g_iForward[ FW_CORE_CURE_PRE ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	if( g_iForwardReturn >= PLUGIN_HANDLED )
	{
		return false;
	}
	
	ExecuteForward( g_iForward[ FW_CORE_CURE ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	bitsum_del( g_bIsZombie, i_Client );
	bitsum_del( g_bIsFirstZombie, i_Client );
	bitsum_del( g_bIsLastZombie, i_Client );
	bitsum_del( g_bIsLastHuman, i_Client );

	ExecuteForward( g_iForward[ FW_CORE_CURE_POST ], g_iForwardReturn, i_Client, i_Attacker, i_Force );

	ftLastPlayerUpdate( );

	return true;
}

ftLastPlayerUpdate( )
{
	new i_Client, i_LastZombie, i_LastHuman;

	// Last Zombie
	if( ftGetCountZombie( ) == 1 )
	{
		for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
		{
			if( bitsum_get( g_bIsAlive, i_Client ) && bitsum_get( g_bIsZombie, i_Client ) )
			{
				bitsum_set( g_bIsLastZombie, i_Client );

				i_LastZombie = i_Client;
			}
			else
			{
				bitsum_del( g_bIsLastZombie, i_Client );
			}
		}
	}
	else
	{
		g_bIsForwardCalledLastZombie = false;

		for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
		{
			bitsum_del( g_bIsLastZombie, i_Client );
		}
	}

	if( is_user_valid_alive( i_LastZombie ) && !g_bIsForwardCalledLastZombie )
	{
		ExecuteForward( g_iForward[ FW_CORE_LAST_ZOMBIE ], g_iForwardReturn, i_LastZombie );

		g_bIsForwardCalledLastZombie = true;
	}

	// Last Human
	if( ftGetCountHuman( ) == 1 )
	{
		for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
		{
			if( bitsum_get( g_bIsAlive, i_Client ) && !bitsum_get( g_bIsZombie, i_Client ) )
			{
				bitsum_set( g_bIsLastHuman, i_Client );

				i_LastHuman = i_Client;
			}
			else
			{
				bitsum_del( g_bIsLastHuman, i_Client );
			}
		}
	}
	else
	{
		g_bIsForwardCalledLastHuman = false;

		for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
		{
			bitsum_del( g_bIsLastHuman, i_Client );
		}
	}

	if( is_user_valid_alive( i_LastHuman ) && !g_bIsForwardCalledLastHuman )
	{
		ExecuteForward( g_iForward[ FW_CORE_LAST_HUMAN ], g_iForwardReturn, i_LastHuman );

		g_bIsForwardCalledLastHuman = true;
	}
}