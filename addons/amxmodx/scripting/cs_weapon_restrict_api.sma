/* ===============================================================================

	--------------------------------
	-*- [CS] Weapon Restrict API -*-
	--------------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < fun >
#include < hamsandwich >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[CS] Weapon Restrict API";
new const g_szPluginVersion[ ] = "1.0.0";
new const g_szPluginAuthor[ ] = "RV";

new const g_szEntityWeapon[ ][ ] =
{
	"",
	"weapon_p228",
	"",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
};

const g_iSizeEntityWeapon = sizeof( g_szEntityWeapon );

const m_Item = 4;
const m_Player = 5;
const m_pPlayer = 41;
const m_iId = 43;
// const m_flNextPrimaryAttack = 46;
// const m_flNextSecondaryAttack = 47;
// const m_flNextTimeWeaponIdle = 48;
// const m_iClip = 51;
// const m_iWeaponState = 74;
const m_flNextAttack = 83;
// const m_iFOV = 363;
const m_pActiveItem = 373;

new g_bIsConnected;
new g_bIsAlive;
new g_bHasWeaponRestrict;

new g_iWeaponAllowed[ MAX_PLAYERS + 1 ];
new g_iWeaponDefault[ MAX_PLAYERS + 1 ];

public plugin_init( )
{
	register_plugin( g_szPluginName, g_szPluginVersion, g_szPluginAuthor );

	RegisterHam( Ham_Spawn, "player", "fwHamSpawnPost", true, true );
	RegisterHam( Ham_Killed, "player", "fwHamKilledPost", true, true );

	for( new i_Entity = 0; i_Entity < g_iSizeEntityWeapon; i_Entity ++ )
	{
		if( g_szEntityWeapon[ i_Entity ][ 0 ] )
		{
			RegisterHam( Ham_Item_Deploy, g_szEntityWeapon[ i_Entity ], "fwHamItemDeployPost", true, false );
		}
	}
}

public plugin_natives( )
{
	register_library( "cs_weapon_restrict_api" );

	register_native( "cs_player_weapon_restrict_set", "_player_weapon_restrict_set" );
	register_native( "cs_player_weapon_restrict_get", "_player_weapon_restrict_get" );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	bitsum_del( g_bIsAlive, i_Client );
	bitsum_del( g_bHasWeaponRestrict, i_Client );
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

public fwHamItemDeployPost( i_Entity )
{
	if( !pev_valid( i_Entity ) )
	{
		return;
	}

	new i_Client = get_pdata_cbase( i_Entity, m_pPlayer, m_Item );

	if( !is_user_valid_alive( i_Client ) || !bitsum_get( g_bHasWeaponRestrict, i_Client ) )
	{
		return;
	}

	new i_Weapon = get_pdata_int( i_Entity, m_iId, m_Item );

	if( !( ( 1 << i_Weapon ) & g_iWeaponAllowed[ i_Client ] ) )
	{
		new i_Weapons[ 32 ], i_WeaponsCount;
		new i_WeaponsBitsum = get_user_weapons( i_Client, i_Weapons, i_WeaponsCount );

		if( i_WeaponsBitsum & ( 1 << g_iWeaponDefault[ i_Client ] ) )
		{
			engclient_cmd( i_Client, g_szEntityWeapon[ g_iWeaponDefault[ i_Client ] ] );
		}
		else
		{
			// set_pdata_float( i_Entity, m_flNextPrimaryAttack, 8192.0, m_Item );
			// set_pdata_float( i_Entity, m_flNextSecondaryAttack, 8192.0, m_Item );
			// set_pdata_float( i_Entity, m_flNextTimeWeaponIdle, 8192.0, m_Item );
			set_pdata_float( i_Entity, m_flNextAttack, 8192.0, m_Item );

			set_pev( i_Client, pev_viewmodel2, 0 );
			set_pev( i_Client, pev_weaponmodel2, 0 );
		}
	}
}

public _player_weapon_restrict_set( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new i_WeaponRestrict = get_param( 2 );

	if( !i_WeaponRestrict )
	{
		if( !bitsum_get( g_bHasWeaponRestrict, i_Client ) )
		{
			return true;
		}

		bitsum_del( g_bHasWeaponRestrict, i_Client );

		new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );

		if( pev_valid( i_Entity ) )
		{
			ExecuteHamB( Ham_Item_Deploy, i_Entity );
		}

		return true;
	}

	new i_WeaponAllowed = get_param( 3 ), i_WeaponDefault = get_param( 4 );

	if( !( i_WeaponAllowed & ( 1 << i_WeaponDefault ) ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Allowed default weapon must in allowed weapon bitsum" );

		return false;
	}

	bitsum_set( g_bHasWeaponRestrict, i_Client );

	g_iWeaponAllowed[ i_Client ] = i_WeaponAllowed;
	g_iWeaponDefault[ i_Client ] = i_WeaponDefault;

	new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );

	if( pev_valid( i_Entity ) )
	{
		fwHamItemDeployPost( i_Entity );
	}

	return true;
}

public _player_weapon_restrict_get( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	if( !bitsum_get( g_bHasWeaponRestrict, i_Client ) )
	{
		return false;
	}

	set_param_byref( 2, g_iWeaponAllowed[ i_Client ] );
	set_param_byref( 3, g_iWeaponDefault[ i_Client ] );

	return true;
}

/* ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
} */