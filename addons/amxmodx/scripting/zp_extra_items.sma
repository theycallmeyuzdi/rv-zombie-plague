/* ===============================================================================

	------------------------
	-*- [ZP] Extra Items -*-
	------------------------

	- Discord Server: https://discord.gg/S6Cj3Wn
	- Website:
		* https://rvrealm.com
		* https://community.rvrealm.com/forums/forumdisplay.php?fid=19

=============================================================================== */

#include < amxmodx >
// #include < amxmisc >
#include < hamsandwich >
#include < amx_settings_api >
#include < zp_core >
#include < zp_tokens >

#pragma semicolon 1;

#define bitsum_set(%1,%2)	( %1 |= ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_del(%1,%2)	( %1 &= ~ ( ( 1 << ( %2 - 1 ) ) & 31 ) )
#define bitsum_get(%1,%2)	( %1 & ( ( 1 << ( %2 - 1 ) ) & 31 ) )

#define is_user_valid(%1)			( 1 <= %1 <= MaxClients )
#define is_user_valid_connected(%1)	( is_user_valid( %1 ) && bitsum_get( g_bIsConnected, %1 ) )
#define is_user_valid_alive(%1)		( is_user_valid( %1 ) && bitsum_get( g_bIsAlive, %1 ) )

new const g_szPluginName[ ] = "[ZP] Extra Items";
new const g_szPluginVersion[ ] = ZP_VERSION_STR;
new const g_szPluginAuthor[ ] = ZP_AUTHOR;

new const g_szFileCustomization[ ] = "rv_zombie_plague/zp_extra_items.ini";

enum _:MAX_FORWARDS
{
	FW_EXTRA_ITEM_MENU_LIST = 0,

	FW_EXTRA_ITEM_CHOOSE_PRE,
	FW_EXTRA_ITEM_CHOOSE_POST
};

new Array:g_ExtraItemNameStatic;
new Array:g_ExtraItemName;
new Array:g_ExtraItemInfo;
new Array:g_ExtraItemPrice;
new Array:g_ExtraItemTokens;

new g_bIsConnected;
new g_bIsAlive;

new g_iForward[ MAX_FORWARDS ];
new g_iForwardReturn;
new g_iExtraItemsCount;
new g_iExtraItemsMenuPage[ MAX_PLAYERS + 1 ];

public plugin_init( )
{
	register_plugin( g_szPluginName, g_szPluginVersion, g_szPluginAuthor );

	g_iForward[ FW_EXTRA_ITEM_MENU_LIST ] = CreateMultiForward( "zp_fw_extra_item_menu_list", ET_CONTINUE, FP_CELL, FP_CELL );

	g_iForward[ FW_EXTRA_ITEM_CHOOSE_PRE ] = CreateMultiForward( "zp_fw_extra_item_choose_pre", ET_CONTINUE, FP_CELL, FP_CELL );
	g_iForward[ FW_EXTRA_ITEM_CHOOSE_POST ] = CreateMultiForward( "zp_fw_extra_item_choose_post", ET_IGNORE, FP_CELL, FP_CELL );

	register_dictionary( "zp_extra_items.txt" );

	register_clcmd( "say /extraitems", "ClCmd_ExtraItems" );
	register_clcmd( "say /items", "ClCmd_ExtraItems" );
	register_clcmd( "say /shop", "ClCmd_ExtraItems" );

	RegisterHam( Ham_Spawn, "player", "fwHamSpawnPost", true, true );
	RegisterHam( Ham_Killed, "player", "fwHamKilledPost", true, true );
}

public plugin_natives( )
{
	register_library( "zp_extra_items" );

	register_native( "zp_extra_item_register", "_extra_item_register" );
	register_native( "zp_extra_item_get_id", "_extra_item_get_id" );
	register_native( "zp_extra_item_get_name_static", "_extra_item_get_name_static" );
	register_native( "zp_extra_item_get_name", "_extra_item_get_name" );
	register_native( "zp_extra_item_get_info", "_extra_item_get_info" );
	register_native( "zp_extra_item_get_price", "_extra_item_get_price" );
	register_native( "zp_extra_item_get_tokens", "_extra_item_get_tokens" );
	register_native( "zp_extra_item_get_count", "_extra_item_get_count" );
	register_native( "zp_extra_item_show_menu", "_extra_item_show_menu" );
	register_native( "zp_extra_item_buy", "_extra_item_buy" );

	g_ExtraItemNameStatic = ArrayCreate( 32, 1 );
	g_ExtraItemName = ArrayCreate( 32, 1 );
	g_ExtraItemInfo = ArrayCreate( 32, 1 );
	g_ExtraItemPrice = ArrayCreate( 1, 1 );
	g_ExtraItemTokens = ArrayCreate( 1, 1 );
}

public client_putinserver( i_Client )
{
	bitsum_set( g_bIsConnected, i_Client );
}

public client_disconnected( i_Client )
{
	bitsum_del( g_bIsConnected, i_Client );
	bitsum_del( g_bIsAlive, i_Client );

	g_iExtraItemsMenuPage[ i_Client ] = 0;
}

public ClCmd_ExtraItems( i_Client )
{
	if( is_user_valid_alive( i_Client ) )
	{
		ftExtraItemShowMenu( i_Client );
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

public fwHamKilledPost( i_Victim, i_Attacker )
{
	bitsum_del( g_bIsAlive, i_Victim );
}

public _extra_item_register( /* i_Plugin, i_Parameter */ )
{
	new sz_ExtraItemName[ 32 ];
	get_string( 1, sz_ExtraItemName, charsmax( sz_ExtraItemName ) );

	if( !strlen( sz_ExtraItemName ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Extra item name is empty" );

		return ZP_OUT_OF_RANGE;
	}

	if( ArrayFindString( g_ExtraItemNameStatic, sz_ExtraItemName ) != -1 )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Extra item already exists (^"%s^")", sz_ExtraItemName );

		return ZP_OUT_OF_RANGE;
	}

	new sz_ExtraItemInfo[ 32 ];
	get_string( 2, sz_ExtraItemInfo, charsmax( sz_ExtraItemInfo ) );

	if( !strlen( sz_ExtraItemInfo ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Extra item info is empty" );

		return ZP_OUT_OF_RANGE;
	}

	new sz_ExtraItemNameStatic[ 32 ];
	copy( sz_ExtraItemNameStatic, charsmax( sz_ExtraItemNameStatic ), sz_ExtraItemName );

	ArrayPushString( g_ExtraItemNameStatic, sz_ExtraItemNameStatic );

	if( !amx_load_setting_string( g_szFileCustomization, sz_ExtraItemNameStatic, "NAME", sz_ExtraItemName, charsmax( sz_ExtraItemName ) ) )
	{
		amx_save_setting_string( g_szFileCustomization, sz_ExtraItemNameStatic, "NAME", sz_ExtraItemName );
	}

	ArrayPushString( g_ExtraItemName, sz_ExtraItemName );

	if( !amx_load_setting_string( g_szFileCustomization, sz_ExtraItemNameStatic, "INFO", sz_ExtraItemInfo, charsmax( sz_ExtraItemInfo ) ) )
	{
		amx_save_setting_string( g_szFileCustomization, sz_ExtraItemNameStatic, "INFO", sz_ExtraItemInfo );
	}

	ArrayPushString( g_ExtraItemInfo, sz_ExtraItemInfo );

	new i_ExtraItemPrice, i_ExtraItemTokens;

	if( !amx_load_setting_int( g_szFileCustomization, sz_ExtraItemNameStatic, "PRICE", i_ExtraItemPrice ) )
	{
		i_ExtraItemPrice = get_param( 3 );

		amx_save_setting_int( g_szFileCustomization, sz_ExtraItemNameStatic, "PRICE", i_ExtraItemPrice );
	}

	ArrayPushCell( g_ExtraItemPrice, i_ExtraItemPrice );

	if( !amx_load_setting_int( g_szFileCustomization, sz_ExtraItemNameStatic, "TOKENS", i_ExtraItemTokens ) )
	{
		i_ExtraItemTokens = get_param( 4 );
		
		amx_save_setting_int( g_szFileCustomization, sz_ExtraItemNameStatic, "TOKENS", i_ExtraItemTokens );
	}

	ArrayPushCell( g_ExtraItemTokens, i_ExtraItemTokens );

	g_iExtraItemsCount ++;

	return g_iExtraItemsCount - 1;
}

public _extra_item_get_id( /* i_Plugin, i_Parameter */ )
{
	new sz_ExtraItemNameStatic[ 32 ];
	get_string( 1, sz_ExtraItemNameStatic, charsmax( sz_ExtraItemNameStatic ) );

	if( !strlen( sz_ExtraItemNameStatic ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Extra item name is empty" );

		return ZP_OUT_OF_RANGE;
	}

	return ArrayFindString( g_ExtraItemNameStatic, sz_ExtraItemNameStatic );
}

public _extra_item_get_name_static( /* i_Plugin, i_Parameter */ )
{
	new i_ExtraItem = get_param( 1 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return false;
	}
	
	new sz_ExtraItemNameStatic[ 32 ];
	ArrayGetString( g_ExtraItemNameStatic, i_ExtraItem, sz_ExtraItemNameStatic, charsmax( sz_ExtraItemNameStatic ) );

	set_string( 2, sz_ExtraItemNameStatic, get_param( 3 ) );

	return true;
}

public _extra_item_get_name( /* i_Plugin, i_Parameter */ )
{
	new i_ExtraItem = get_param( 1 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return false;
	}
	
	new sz_ExtraItemName[ 32 ];
	ArrayGetString( g_ExtraItemName, i_ExtraItem, sz_ExtraItemName, charsmax( sz_ExtraItemName ) );

	set_string( 2, sz_ExtraItemName, get_param( 3 ) );

	return true;
}

public _extra_item_get_info( /* i_Plugin, i_Parameter */ )
{
	new i_ExtraItem = get_param( 1 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return false;
	}
	
	new sz_ExtraItemInfo[ 32 ];
	ArrayGetString( g_ExtraItemInfo, i_ExtraItem, sz_ExtraItemInfo, charsmax( sz_ExtraItemInfo ) );

	set_string( 2, sz_ExtraItemInfo, get_param( 3 ) );

	return true;
}

public _extra_item_get_price( /* i_Plugin, i_Parameter */ )
{
	new i_ExtraItem = get_param( 1 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return ZP_OUT_OF_RANGE;
	}

	return ArrayGetCell( g_ExtraItemPrice, i_ExtraItem );
}

public _extra_item_get_tokens( /* i_Plugin, i_Parameter */ )
{
	new i_ExtraItem = get_param( 1 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return ZP_OUT_OF_RANGE;
	}

	return ArrayGetCell( g_ExtraItemTokens, i_ExtraItem );
}

public _extra_item_get_count( /* i_Plugin, i_Parameter */ )
{
	return g_iExtraItemsCount;
}

public _extra_item_show_menu( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_alive( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Player is not alive (%d)", i_Client );

		return false;
	}

	return ftExtraItemShowMenu( i_Client );
}

public _extra_item_buy( /* i_Plugin, i_Parameter */ )
{
	new i_Client = get_param( 1 );

	if( !is_user_valid_alive( i_Client ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Player is not alive (%d)", i_Client );

		return false;
	}

	new i_ExtraItem = get_param( 2 );

	if( !( 0 <= i_ExtraItem < g_iExtraItemsCount ) )
	{
		log_error( AMX_ERR_NATIVE, "[ZP] Invalid extra item (%d)", i_ExtraItem );

		return false;
	}

	return ftExtraItemBuy( i_Client, i_ExtraItem );
}

public ftExtraItemMenuHandle( i_Client, i_Menu, i_Item )
{
	if( i_Item == MENU_EXIT )
	{
		g_iExtraItemsMenuPage[ i_Client ] = 0;

		menu_destroy( i_Menu );

		return;
	}

	if( !is_user_valid_alive( i_Client ) )
	{
		menu_destroy( i_Menu );

		return;
	}

	g_iExtraItemsMenuPage[ i_Client ] = i_Item / 7;

	new i_Access, sz_ItemInfo[ 2 ], i_Callback;
	menu_item_getinfo( i_Menu, i_Item, i_Access, sz_ItemInfo, charsmax( sz_ItemInfo ), _, _, i_Callback );

	new i_ExtraItem = sz_ItemInfo[ 0 ];

	ftExtraItemBuy( i_Client, i_ExtraItem );

	menu_destroy( i_Menu );
}

/* ftGetCountBitsum( i_Bitsum )
{
	i_Bitsum = ( i_Bitsum - ( ( i_Bitsum >> 1 ) & 0x55555555 ) );
	i_Bitsum = ( i_Bitsum & 0x33333333 ) + ( ( i_Bitsum >> 2 ) & 0x33333333 );

	return ( ( ( i_Bitsum + ( i_Bitsum >> 4 ) & 0xF0F0F0F ) * 0x1010101 ) >> 24 );
} */

ftExtraItemShowMenu( i_Client )
{
	static sz_Menu[ 128 ], sz_ExtraItemName[ 32 ], sz_ExtraItemInfo[ 32 ], i_ExtraItemPrice, i_ExtraItemTokens;
	formatex( sz_Menu, charsmax( sz_Menu ), "%L:\r", i_Client, "MENU_TITLE_EXTRA_ITEMS" );

	new sz_ItemInfo[ 2 ], i_Menu = menu_create( sz_Menu, "ftExtraItemMenuHandle" );

	new const sz_MLTokens[ MAX_TOKENS ][ ] =
	{
		"INFO_TOKENS_BRONZE_SHORT",
		"INFO_TOKENS_SILVER_SHORT",
		"INFO_TOKENS_GOLD_SHORT",
		"INFO_TOKENS_DIAMOND_SHORT"
	};

	for( new i_ExtraItem = 0; i_ExtraItem < g_iExtraItemsCount; i_ExtraItem ++ )
	{
		ExecuteForward( g_iForward[ FW_EXTRA_ITEM_MENU_LIST ], g_iForwardReturn, i_Client, i_ExtraItem );

		if( g_iForwardReturn >= ZP_MENU_ITEM_DO_NOT_SHOW )
		{
			continue;
		}

		ArrayGetString( g_ExtraItemName, i_ExtraItem, sz_ExtraItemName, charsmax( sz_ExtraItemName ) );
		ArrayGetString( g_ExtraItemInfo, i_ExtraItem, sz_ExtraItemInfo, charsmax( sz_ExtraItemInfo ) );

		i_ExtraItemPrice = ArrayGetCell( g_ExtraItemPrice, i_ExtraItem );
		i_ExtraItemTokens = ArrayGetCell( g_ExtraItemTokens, i_ExtraItem );

		if( g_iForwardReturn >= ZP_MENU_ITEM_UNAVAILABLE )
		{
			formatex( sz_Menu, charsmax( sz_Menu ), "\d%s \r%s \y%d %L", sz_ExtraItemName, sz_ExtraItemInfo, i_ExtraItemPrice, i_Client, sz_MLTokens[ i_ExtraItemTokens ] );
		}
		else
		{
			formatex( sz_Menu, charsmax( sz_Menu ), "\w%s \r%s \y%d %L", sz_ExtraItemName, sz_ExtraItemInfo, i_ExtraItemPrice, i_Client, sz_MLTokens[ i_ExtraItemTokens ] );
		}

		sz_ItemInfo[ 0 ] = i_ExtraItem;
		sz_ItemInfo[ 1 ] = 0;

		menu_additem( i_Menu, sz_Menu, sz_ItemInfo );
	}

	if( !menu_items( i_Menu ) )
	{
		client_print_color( i_Client, print_team_default, "%s %L", ZP_PREFIX_COLOR, i_Client, "MSG_EXTRA_ITEMS_EMPTY" );

		menu_destroy( i_Menu );

		return false;
	}

	formatex( sz_Menu, charsmax( sz_Menu ), "%L", i_Client, "MENU_BACK" );
	menu_setprop( i_Menu, MPROP_BACKNAME, sz_Menu );

	formatex( sz_Menu, charsmax( sz_Menu ), "%L", i_Client, "MENU_NEXT" );
	menu_setprop( i_Menu, MPROP_NEXTNAME, sz_Menu );

	formatex( sz_Menu, charsmax( sz_Menu ), "%L", i_Client, "MENU_EXIT" );
	menu_setprop( i_Menu, MPROP_EXITNAME, sz_Menu );

	g_iExtraItemsMenuPage[ i_Client ] = min( g_iExtraItemsMenuPage[ i_Client ], menu_pages( i_Menu ) - 1 );

	menu_display( i_Client, i_Menu, g_iExtraItemsMenuPage[ i_Client ] );

	return true;
}

ftExtraItemBuy( i_Client, i_ExtraItem )
{
	ExecuteForward( g_iForward[ FW_EXTRA_ITEM_CHOOSE_PRE ], g_iForwardReturn, i_Client, i_ExtraItem );

	if( g_iForwardReturn >= PLUGIN_HANDLED )
	{
		return false;
	}

	ExecuteForward( g_iForward[ FW_EXTRA_ITEM_CHOOSE_POST ], g_iForwardReturn, i_Client, i_ExtraItem );

	return true;
}