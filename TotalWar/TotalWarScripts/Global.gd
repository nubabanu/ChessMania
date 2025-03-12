extends Node

var white_purchased_pieces = {}
var black_purchased_pieces = {}
var turn = 0
var TOTAL_BALANCE = 50
var playable_lines = 3

enum Player { WHITE, BLACK }

var selected_pieces = {}  # Dictionary to track selected pieces
const MAIN_MENU = "res://scenesMenu/Menu.tscn"
const SHOP = "res://TotalWar/Scenes/Shop.tscn"
const BLACK_SHOP = "res://TotalWar/Scenes/BlackShop.tscn"
const TOTAL_WAR = "res://TotalWar/Scenes/TotalWar.tscn"
const OPTIONS = "res://TotalWar/Scenes/Options.tscn"
