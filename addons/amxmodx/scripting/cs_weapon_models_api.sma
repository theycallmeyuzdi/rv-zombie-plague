/* ===============================================================================

	------------------------------
	-*- [CS] Weapon Models API -*-
	------------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[CS] Weapon Models API";
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
// const m_flNextAttack = 83;
// const m_iFOV = 363;
const m_pActiveItem = 373;

new Array:g_WeaponPModel;
new Array:g_WeaponVModel;

new g_bIsConnected;
new g_bIsAlive;

new g_iWeaponPModelPosition[ MAX_PLAYERS + 1 ][ CSW_P90 + 1 ];
new g_iWeaponVModelPosition[ MAX_PLAYERS + 1 ][ CSW_P90 + 1 ];
new g_iWeaponPModelsCount;
new g_iWeaponVModelsCount;

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

	g_WeaponPModel = ArrayCreate( 128, 1 );
	g_WeaponVModel = ArrayCreate( 128, 1 );

	new i_Client, i_Weapon;

	for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
	{
		for( i_Weapon = CSW_P228; i_Weapon < CSW_P90; i_Weapon ++ )
		{
			g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] = -1;
			g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] = -1;
		}
	}
}

public plugin_natives( )
{
	register_library( "cs_weapon_models_api" );

	register_native( "cs_player_weapon_p_model_set", "_player_weapon_p_model_set" );
	register_native( "cs_player_weapon_p_model_reset", "_player_weapon_p_model_reset" );
	register_native( "cs_player_weapon_v_model_set", "_player_weapon_v_model_set" );
	register_native( "cs_player_weapon_v_model_reset", "_player_weapon_v_model_reset" );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	bitsum_del( g_bIsAlive, i_Client );

	for( new i_Weapon = CSW_P228; i_Weapon < CSW_P90; i_Weapon ++ )
	{
		if( g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] != -1 )
		{
			ftWeaponPModelRemove( i_Client, i_Weapon );
		}

		if( g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] != -1 )
		{
			ftWeaponVModelRemove( i_Client, i_Weapon );
		}
	}
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

	if( !is_user_valid_alive( i_Client ) )
	{
		return;
	}

	new i_Weapon = get_pdata_int( i_Entity, m_iId, m_Item );

	if( g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] != -1 )
	{
		new sz_PModel[ 128 ];
		ArrayGetString( g_WeaponPModel, g_iWeaponPModelPosition[ i_Client ][ i_Weapon ], sz_PModel, charsmax( sz_PModel ) );

		set_pev( i_Client, pev_weaponmodel2, sz_PModel );
	}

	if( g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] != -1 )
	{
		new sz_VModel[ 128 ];
		ArrayGetString( g_WeaponVModel, g_iWeaponVModelPosition[ i_Client ][ i_Weapon ], sz_VModel, charsmax( sz_VModel ) );

		set_pev( i_Client, pev_viewmodel2, sz_VModel );
	}
}

public _player_weapon_p_model_set( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new i_Weapon = get_param( 2 );

	if( !( CSW_P228 <= i_Weapon <= CSW_P90 ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Invalid weapon (%d)", i_Weapon );

		return false;
	}

	new sz_PModel[ 128 ];
	get_string( 3, sz_PModel, charsmax( sz_PModel ) );

	if( g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] == -1 )
	{
		g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] = g_iWeaponPModelsCount;

		ArrayPushString( g_WeaponPModel, sz_PModel );

		g_iWeaponPModelsCount ++;
	}
	else
	{
		ArraySetString( g_WeaponPModel, g_iWeaponPModelPosition[ i_Client ][ i_Weapon ], sz_PModel );
	}

	new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );
	new i_WeaponCurrent = pev_valid( i_Entity ) ? get_pdata_int( i_Entity, m_iId, m_Item ) : -1;

	if( i_Weapon == i_WeaponCurrent )
	{
		fwHamItemDeployPost( i_Entity );
	}

	return true;
}

public _player_weapon_p_model_reset( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new i_Weapon = get_param( 2 );

	if( !( CSW_P228 <= i_Weapon <= CSW_P90 ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Invalid weapon (%d)", i_Weapon );

		return false;
	}

	if( g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] == -1 )
	{
		return true;
	}

	ftWeaponPModelRemove( i_Client, i_Weapon );

	new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );
	new i_WeaponCurrent = pev_valid( i_Entity ) ? get_pdata_int( i_Entity, m_iId, m_Item ) : -1;

	if( i_Weapon == i_WeaponCurrent )
	{
		ExecuteHamB( Ham_Item_Deploy, i_Entity );
	}

	return true;
}

public _player_weapon_v_model_set( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new i_Weapon = get_param( 2 );

	if( !( CSW_P228 <= i_Weapon <= CSW_P90 ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Invalid weapon (%d)", i_Weapon );

		return false;
	}

	new sz_VModel[ 128 ];
	get_string( 3, sz_VModel, charsmax( sz_VModel ) );

	if( g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] == -1 )
	{
		g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] = g_iWeaponVModelsCount;

		ArrayPushString( g_WeaponVModel, sz_VModel );

		g_iWeaponVModelsCount ++;
	}
	else
	{
		ArraySetString( g_WeaponVModel, g_iWeaponVModelPosition[ i_Client ][ i_Weapon ], sz_VModel );
	}

	new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );
	new i_WeaponCurrent = pev_valid( i_Entity ) ? get_pdata_int( i_Entity, m_iId, m_Item ) : -1;

	if( i_Weapon == i_WeaponCurrent )
	{
		fwHamItemDeployPost( i_Entity );
	}

	return true;
}

public _player_weapon_v_model_reset( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_connected( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Player is not in-game (%d)", i_Client );

		return false;
	}

	new i_Weapon = get_param( 2 );

	if( !( CSW_P228 <= i_Weapon <= CSW_P90 ) )
	{
		log_error( AMX_ERR_NATIVE, "[CS] Invalid weapon (%d)", i_Weapon );

		return false;
	}

	if( g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] == -1 )
	{
		return true;
	}

	ftWeaponVModelRemove( i_Client, i_Weapon );

	new i_Entity = get_pdata_cbase( i_Client, m_pActiveItem, m_Player );
	new i_WeaponCurrent = pev_valid( i_Entity ) ? get_pdata_int( i_Entity, m_iId, m_Item ) : -1;

	if( i_Weapon == i_WeaponCurrent )
	{
		ExecuteHamB( Ham_Item_Deploy, i_Entity );
	}

	return true;
}

/* ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
} */

ftWeaponPModelRemove( i_Client, i_Weapon )
{
	new i_Position = g_iWeaponPModelPosition[ i_Client ][ i_Weapon ];

	ArrayDeleteItem( g_WeaponPModel, i_Position );

	g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] = -1;
	g_iWeaponPModelsCount --;

	for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
	{
		for( i_Weapon = CSW_P228; i_Weapon <= CSW_P90; i_Weapon ++ )
		{
			if( g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] > i_Position )
			{
				g_iWeaponPModelPosition[ i_Client ][ i_Weapon ] --;
			}
		}
	}
}

ftWeaponVModelRemove( i_Client, i_Weapon )
{
	new i_Position = g_iWeaponVModelPosition[ i_Client ][ i_Weapon ];

	ArrayDeleteItem( g_WeaponVModel, i_Position );

	g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] = -1;
	g_iWeaponVModelsCount --;

	for( i_Client = 1; i_Client <= MaxClients; i_Client ++ )
	{
		for( i_Weapon = CSW_P228; i_Weapon <= CSW_P90; i_Weapon ++ )
		{
			if( g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] > i_Position )
			{
				g_iWeaponVModelPosition[ i_Client ][ i_Weapon ] --;
			}
		}
	}
}