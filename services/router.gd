extends Node

"""
Router script
Usage: define routes to different menus/HUDs so that the any scene can request a redirection to a
menu/HUD and the main scene will handle the redirection through the redirect_to signal.

To avoid spelling mistakes, an enum is used to define the names of possible routes.
"""

signal redirect_to(route: ROUTE_NAME)

enum ROUTE_NAME {
	MAIN_MENU,
	SKIN_CIRCUIT_SELECTOR,
	RACE_HUD,
	TIMES_MENU,
}

const ROUTES: Dictionary[ROUTE_NAME, Resource] = {
	ROUTE_NAME.MAIN_MENU: preload("uid://bpfuekwshxnsq"),
	ROUTE_NAME.SKIN_CIRCUIT_SELECTOR: preload("uid://1udkdnfvon3y"),
	ROUTE_NAME.RACE_HUD: preload("uid://b4b7wjspog7em"),
	ROUTE_NAME.TIMES_MENU: preload("uid://djs0lutrxdt14")
}
