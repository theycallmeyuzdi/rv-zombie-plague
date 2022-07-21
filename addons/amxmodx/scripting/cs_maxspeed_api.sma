/* ===============================================================================

	--------------------------
	-*- [CS] Max Speed API -*-
	--------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
#include < fun >
#include < hamsandwich >
#include < cs_maxspeed_api_const >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[CS] Max Speed API";
new const g_szPluginVersion[ ] = "1.0.0";
new const g_szPluginAuthor[ ] = "RV";

new g_bIsConnected;
new g_bIsAlive;
new g_bHasMaxSpeed;

new bool:g_bIsFreezeTime;

new Float:g_flMaxSpeed[ MAX_PLAYERS + 1 ];

public plugin_init( )
{
	register_plugin( g_szPluginName, g_szPluginVersion, g_szPluginAuthor );

	register_event( "HLTV", "ftEventHLTV", "a", "1=0", "2=0" );
	
	register_logevent( "ftLogeventRoundStart", 2, "1=Round_Start" );

	RegisterHam( Ham_Spawn, "player", "fwHamSpawnPost", true, true );
	RegisterHam( Ham_Killed, "player", "fwHamKilledPost", true, true );
	RegisterHam( Ham_CS_Player_ResetMaxSpeed, "player", "fwHamCSPlayerResetMaxSpeedPost", true, true );
}

public plugin_natives( )
{
	register_library( "cs_maxspeed_api" );

	register_native( "cs_player_maxspeed_set", "_player_maxspeed_set" );
	register_native( "cs_player_maxspeed_reset", "_player_maxspeed_reset" );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	bitsum_del( g_bIsAlive, i_Client );
	bitsum_del( g_bHasMaxSpeed, i_Client );
}

public ftEventHLTV( )
{
	g_bIsFreezeTime = true;
}

public ftLogeventRoundStart( )
{
	g_bIsFreezeTime = false;
}

public fwHamSpawnPost( i_Client )
{
	if( !is_user_alive( i_Client ) )
	{
		return;
	}

	bitsum_set( g_bIsAlive, i_Client );
}

public fwHamKilledPost( i_Victim /* , i_Attacker */ )
{
	bitsum_del( g_bIsAlive, i_Victim );
}

public fwHamCSPlayerResetMaxSpeedPost( i_Client )
{
	if( !is_user_valid_alive( i_Client ) || !bitsum_get( g_bHasMaxSpeed, i_Client ) || g_bIsFreezeTime )
	{
		return;
	}

	set_user_maxspeed( i_Client, ( CS_MAXSPEED_BARRIER_MIN <= g_flMaxSpeed[ i_Client ] <= CS_MAXSPEED_BARRIER_MAX ) ? ( get_user_maxspeed( i_Client ) * g_flMaxSpeed[ i_Client ] ) : g_flMaxSpeed[ i_Client ] );
}

public _player_maxspeed_set( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new Float:fl_MaxSpeed = get_param_f( 2 );

	if( fl_MaxSpeed < 0.0 )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Invalid maxspeed value (%.2f)", fl_MaxSpeed );

		return false;
	}

	bitsum_set( g_bHasMaxSpeed, i_Client );

	g_flMaxSpeed[ i_Client ] = fl_MaxSpeed;

	ExecuteHamB( Ham_CS_Player_ResetMaxSpeed, i_Client );

	return true;
}

public _player_maxspeed_reset( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	if( !bitsum_get( g_bHasMaxSpeed, i_Client ) )
	{
		return true;
	}

	bitsum_del( g_bHasMaxSpeed, i_Client );

	ExecuteHamB( Ham_CS_Player_ResetMaxSpeed, i_Client );

	return true;
}

/* ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
} */