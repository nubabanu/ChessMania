extends Sprite2D

const BOARD_LENGTH = 10
const BOARD_WIDTH = 13
const CELL_WIDTH = 90

# -- Standard Chess Textures-------------------
const TEXTURE_HOLDER = preload("res://Tamerlane/Scenes/texture_holder.tscn")
const BLACK_BISHOP = preload("res://Tamerlane/LanePieces/Chess_bdl45.svg")
const BLACK_KING = preload("res://Tamerlane/LanePieces/Chess_kdl44.png")
const BLACK_KNIGHT = preload("res://Tamerlane/LanePieces/Chess_ndl45.svg")
const BLACK_PAWN = preload("res://Tamerlane/LanePieces/Chess_pdl44.png")
const BLACK_QUEEN = preload("res://Assets/black_queen.png")
const BLACK_ROOK = preload("res://Tamerlane/LanePieces/Chess_rdl45.svg")
const WHITE_BISHOP = preload("res://Assets/white_bishop.png")
const WHITE_KING = preload("res://Tamerlane/LanePieces/Chess_kll45.svg")
const WHITE_KNIGHT = preload("res://Tamerlane/LanePieces/Chess_nll45.svg")
const WHITE_PAWN = preload("res://Tamerlane/LanePieces/Chess_pll45.svg")
const WHITE_QUEEN = preload("res://Assets/white_queen.png")
const WHITE_ROOK = preload("res://Tamerlane/LanePieces/Chess_rll45.svg")

const TURN_WHITE = preload("res://Assets/turn-white.png")
const TURN_BLACK = preload("res://Assets/turn-black.png")
const PIECE_MOVE = preload("res://Tamerlane/LanePieces/Piece_move_purple.png")

# -- Tamerlane Piece Textures --
const WHITE_ELEPHANT = preload("res://Tamerlane/LanePieces/Elephant_white_45x45.png")
const WHITE_CAMEL = preload("res://Tamerlane/LanePieces/Chess_sll44.png")
const WHITE_WAR_ENGINE = preload("res://Tamerlane/LanePieces/Chess_mll44.png")
const WHITE_PICKET = preload("res://Tamerlane/LanePieces/Chess_bll44.png")
const WHITE_GIRAFFE = preload("res://Tamerlane/LanePieces/Chess_Gll45.svg")
const WHITE_GENERAL = preload("res://Tamerlane/LanePieces/Chess_qll45.svg")
const WHITE_VIZIER = preload("res://Tamerlane/LanePieces/Chess_gll44.png")

const BLACK_ELEPHANT = preload("res://Tamerlane/LanePieces/Chess_edl45.svg")
const BLACK_CAMEL = preload("res://Tamerlane/LanePieces/Chess_sdl44.png")
const BLACK_WAR_ENGINE = preload("res://Tamerlane/LanePieces/Chess_mdl44.png")
const BLACK_PICKET = preload("res://Tamerlane/LanePieces/Chess_bdl45.svg")
const BLACK_GIRAFFE = preload("res://Tamerlane/LanePieces/Chess_Gdl45.svg")
const BLACK_GENERAL = preload("res://Tamerlane/LanePieces/Chess_qdl44.png")
const BLACK_VIZIER = preload("res://Tamerlane/LanePieces/Chess_gdl44.png")

@onready var pieces = $Pieces
@onready var dots = $Dots
@onready var turn = $Turn


var board : Array = []
var white : bool = true   
var state : bool = false 
var moves = []
var selected_piece : Vector2

var promotion_square = null

var white_king = false
var black_king = false
var white_rook_left = false
var white_rook_right = false
var black_rook_left = false
var black_rook_right = false

var white_king_pos = Vector2(1, 6)
var black_king_pos = Vector2(8, 6)

var white_king_switch_used = false
var black_king_switch_used = false

var fifty_move_rule = 0
var unique_board_moves : Array = []
var amount_of_same : Array = []


func _ready():
        print("pieces is:", pieces) 
        board.clear()

        # Tamerlane layout (10 rows, 13 columns), with citadels at columns 0 & 12:
        board.append([0,  7,  0,  8,  0,  9,  0,  9,  0,  8,  0,  7,  0]) # row 0
        board.append([0,  4,  2, 10, 11, 12,  6, 13, 11, 10,  2,  4,  0]) # row 1
        board.append([0,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  0]) # row 2
        for _i in range(4):
                board.append([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])         # rows 3..6
        board.append([0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0]) # row 7
        board.append([0, -4, -2, -10, -11, -12, -6, -13, -11, -10, -2, -4, 0]) # row 8
        board.append([0, -7,  0, -8,  0, -9,  0, -9,  0, -8,  0, -7,  0]) # row 9

        display_board()

        # Connect promotion‐button signals
        var white_buttons = get_tree().get_nodes_in_group("white_pieces")
        var black_buttons = get_tree().get_nodes_in_group("black_pieces")
        for button in white_buttons:
                button.pressed.connect(self._on_button_pressed.bind(button))
        for button in black_buttons:
                button.pressed.connect(self._on_button_pressed.bind(button))


func _input(event):
        if event is InputEventMouseButton and event.pressed and promotion_square == null:
                if event.button_index == MOUSE_BUTTON_LEFT:
                        if is_mouse_out():
                                return
                        var var1 = snapped(get_global_mouse_position().x, 0) / CELL_WIDTH
                        var var2 = abs(snapped(get_global_mouse_position().y, 0)) / CELL_WIDTH

                        # Selecting or moving
                        if not state and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0)):
                                selected_piece = Vector2(var2, var1)
                                show_options()
                                state = true
                        elif state:
                                set_move(var2, var1)


func is_mouse_out():
        if get_rect().has_point(to_local(get_global_mouse_position())):
                return false
        return true


func display_board():
        # Clear existing child sprites
        for child in pieces.get_children():
                child.queue_free() 

        # Loop through board
        for i in BOARD_LENGTH:
                for j in BOARD_WIDTH:
                        var holder = TEXTURE_HOLDER.instantiate()
                        pieces.add_child(holder)
                        holder.global_position = Vector2(
                                j * CELL_WIDTH + (CELL_WIDTH / 2),
                                -i * CELL_WIDTH - (CELL_WIDTH / 2)
                        )
                        match board[i][j]:
                                # Standard
                                -6: holder.texture = BLACK_KING
                                -5: holder.texture = BLACK_QUEEN
                                -4: holder.texture = BLACK_ROOK
                                -3: holder.texture = BLACK_BISHOP
                                -2: holder.texture = BLACK_KNIGHT
                                -1: holder.texture = BLACK_PAWN

                                6:  holder.texture = WHITE_KING
                                5:  holder.texture = WHITE_QUEEN
                                4:  holder.texture = WHITE_ROOK
                                3:  holder.texture = WHITE_BISHOP
                                2:  holder.texture = WHITE_KNIGHT
                                1:  holder.texture = WHITE_PAWN

                                # Tamerlane codes:
                                -7:  holder.texture = BLACK_ELEPHANT
                                -8:  holder.texture = BLACK_CAMEL
                                -9:  holder.texture = BLACK_WAR_ENGINE
                                -10: holder.texture = BLACK_PICKET
                                -11: holder.texture = BLACK_GIRAFFE
                                -12: holder.texture = BLACK_GENERAL
                                -13: holder.texture = BLACK_VIZIER

                                7:   holder.texture = WHITE_ELEPHANT
                                8:   holder.texture = WHITE_CAMEL
                                9:   holder.texture = WHITE_WAR_ENGINE
                                10:  holder.texture = WHITE_PICKET
                                11:  holder.texture = WHITE_GIRAFFE
                                12:  holder.texture = WHITE_GENERAL
                                13:  holder.texture = WHITE_VIZIER

                                0:
                                        holder.texture = null

        if white:
                turn.texture = TURN_WHITE
        else:
                turn.texture = TURN_BLACK


func show_options():
        moves = get_moves(selected_piece)
        if moves.size() == 0:
                state = false
                return
        show_dots()


func show_dots():
        for i in moves:
                var holder = TEXTURE_HOLDER.instantiate()
                dots.add_child(holder)
                holder.texture = PIECE_MOVE
                holder.global_position = Vector2(
                        i.y * CELL_WIDTH + (CELL_WIDTH / 2),
                        -i.x * CELL_WIDTH - (CELL_WIDTH / 2)
                )


func delete_dots():
        for child in dots.get_children():
                child.queue_free()


func set_move(var2, var1):
        for i in moves:
                if i.x == var2 and i.y == var1:
                        fifty_move_rule += 1
                        # Reset if capturing
                        if is_enemy(Vector2(var2, var1)):
                                fifty_move_rule = 0

                        var moving_piece = board[selected_piece.x][selected_piece.y]
                        # Place piece
                        board[var2][var1] = moving_piece
                        board[selected_piece.x][selected_piece.y] = 0

                        # If it's the king, update king pos
                        if abs(moving_piece) == 6:
                                if moving_piece > 0:
                                        white_king_pos = Vector2(var2, var1)
                                else:
                                        black_king_pos = Vector2(var2, var1)

                                # If occupying opponent's citadel => "win"
                                if moving_piece > 0 and white_king_pos == Vector2(8, 12):
                                        print("Win: White King occupies Black's citadel!")
                                elif moving_piece < 0 and black_king_pos == Vector2(1, 0):
                                        print("Win: Black King occupies White's citadel!")

                        white = not white
                        threefold_position(board)
                        display_board()
                        break

        delete_dots()
        state = false

        # Re-select if we just moved onto a square that still belongs to the same color
        if ((selected_piece.x != var2 or selected_piece.y != var1)
                and ((white and board[var2][var1] > 0) or (not white and board[var2][var1] < 0))):
                selected_piece = Vector2(var2, var1)
                show_options()
                state = true
        else:
                if is_stalemate():
                        if (white and is_in_check(white_king_pos)) or (not white and is_in_check(black_king_pos)):
                                print("CHECKMATE")
                        else:
                                print("Win")

                if fifty_move_rule == 50:
                        print("DRAW")
                elif insufficient_material(): # FIXED TYPO HERE
                        print("DRAW")


func get_moves(selected: Vector2):
        var _moves = []
        var piece = board[selected.x][selected.y]
        match abs(piece):
                1:  _moves = get_pawn_moves(selected)
                2:  _moves = get_knight_moves(selected)
                3:  _moves = get_bishop_moves(selected)
                4:  _moves = get_rook_moves(selected)
                5:  _moves = get_queen_moves(selected)
                6:  _moves = get_king_moves(selected)
                7:  _moves = get_elephant_moves(selected)
                8:  _moves = get_camel_moves(selected)
                9:  _moves = get_war_engine_moves(selected)
                10: _moves = get_picket_moves(selected)
                11: _moves = get_giraffe_moves(selected)
                12: _moves = get_general_moves(selected)
                13: _moves = get_vizier_moves(selected)
        return _moves


# ------------------------------- PAWN --------------------------------
func get_pawn_moves(piece_position: Vector2):
        var _moves = []
        var direction = Vector2(1, 0) if white else Vector2(-1, 0)


        # Forward 1
        var forward = piece_position + direction
        if is_valid_position(forward) and is_empty(forward):
                var stored = board[forward.x][forward.y]
                board[forward.x][forward.y] = board[piece_position.x][piece_position.y]
                board[piece_position.x][piece_position.y] = 0
                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                        _moves.append(forward)
                board[piece_position.x][piece_position.y] = board[forward.x][forward.y]
                board[forward.x][forward.y] = stored

        # Capture diagonally
        for side in [1, -1]:
                var diag = piece_position + Vector2(direction.x, side)
                if is_valid_position(diag) and is_enemy(diag):
                        var captured = board[diag.x][diag.y]
                        var store_me = board[piece_position.x][piece_position.y]
                        board[diag.x][diag.y] = store_me
                        board[piece_position.x][piece_position.y] = 0
                        if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                _moves.append(diag)
                        board[piece_position.x][piece_position.y] = store_me
                        board[diag.x][diag.y] = captured

        return _moves


# ------------------------------- KNIGHT ------------------------------
func get_knight_moves(piece_position: Vector2):
        var _moves = []
        var directions = [
                Vector2(2, 1),  Vector2(2, -1),  Vector2(1, 2),  Vector2(1, -2),
                Vector2(-2, 1), Vector2(-2, -1), Vector2(-1, 2), Vector2(-1, -2)
        ]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                # simulate
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves


# ------------------------------- BISHOP ------------------------------
func get_bishop_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
        for direction in directions:
                var pos = piece_position + direction
                while is_valid_position(pos):
                        if is_empty(pos):
                                var tmp = board[pos.x][pos.y]
                                board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
                                board[pos.x][pos.y] = tmp
                        elif is_enemy(pos):
                                var captured = board[pos.x][pos.y]
                                var store_me = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = store_me
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = store_me
                                board[pos.x][pos.y] = captured
                                break
                        else:
                                break
                        pos += direction
        return _moves


# ------------------------------- ROOK --------------------------------
func get_rook_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0)]
        for direction in directions:
                var pos = piece_position + direction
                while is_valid_position(pos):
                        if is_empty(pos):
                                var tmp = board[pos.x][pos.y]
                                board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
                                board[pos.x][pos.y] = tmp
                        elif is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var self_piece = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = self_piece
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = self_piece
                                board[pos.x][pos.y] = temp
                                break
                        else:
                                break
                        pos += direction
        return _moves


# ------------------------------- QUEEN -------------------------------
func get_queen_moves(piece_position: Vector2):
        var _moves = []
        var directions = [
                Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
                Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
        ]
        for direction in directions:
                var pos = piece_position + direction
                while is_valid_position(pos):
                        if is_empty(pos):
                                var tmp = board[pos.x][pos.y]
                                board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
                                board[pos.x][pos.y] = tmp
                        elif is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var self_piece = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = self_piece
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = self_piece
                                board[pos.x][pos.y] = temp # FIXED: Restored captured piece
                                break
                        else:
                                break
                        pos += direction
        return _moves


# ------------------------------- KING --------------------------------
func get_king_moves(piece_position: Vector2):
        var _moves = []
        var directions = [
                Vector2(0,1), Vector2(0,-1), Vector2(1,0), Vector2(-1,0),
                Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)
        ]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                
                                # FIXED: Checking `pos` rather than the old `white_king_pos`
                                if (white and not is_in_check(pos)) or (not white and not is_in_check(pos)):
                                        _moves.append(pos)
                                        
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves


# ------------------------------- TAMERLANE PIECES --------------------

# ELEPHANT (Pil) - Leaps exactly 2 squares diagonally
func get_elephant_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(2,2), Vector2(2,-2), Vector2(-2,2), Vector2(-2,-2)]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves

# CAMEL (Jamal) - Leaps 3 squares orthogonally, 1 square perpendicularly (Long Knight)
func get_camel_moves(piece_position: Vector2):
        var _moves = []
        var directions = [
                Vector2(3,1),  Vector2(3,-1),  Vector2(1,3),  Vector2(1,-3),
                Vector2(-3,1), Vector2(-3,-1), Vector2(-1,3), Vector2(-1,-3)
        ]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves

# WAR ENGINE (Dabbaba) - Leaps exactly 2 squares orthogonally
func get_war_engine_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(2,0), Vector2(-2,0), Vector2(0,2), Vector2(0,-2)]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves

# PICKET (Talia) - Slides diagonally like a bishop, but must move AT LEAST 2 squares
func get_picket_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
        for dir in directions:
                var step = 1
                var pos = piece_position + dir
                while is_valid_position(pos):
                        if step >= 2:
                                if is_empty(pos):
                                        var tmp = board[pos.x][pos.y]
                                        board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
                                        board[piece_position.x][piece_position.y] = 0
                                        if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                                _moves.append(pos)
                                        board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
                                        board[pos.x][pos.y] = tmp
                                elif is_enemy(pos):
                                        var temp = board[pos.x][pos.y]
                                        var self_piece = board[piece_position.x][piece_position.y]
                                        board[pos.x][pos.y] = self_piece
                                        board[piece_position.x][piece_position.y] = 0
                                        if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                                _moves.append(pos)
                                        board[piece_position.x][piece_position.y] = self_piece
                                        board[pos.x][pos.y] = temp
                                        break
                                else:
                                        break
                        else:
                                if not is_empty(pos):
                                        break
                        pos += dir
                        step += 1
        return _moves

# GIRAFFE (Zurafa) - Moves 1 square diagonally, then SLIDES a minimum of 3 squares orthogonally
func get_giraffe_moves(piece_position: Vector2):
        var _moves = []
        var arms = [
                [Vector2(1,1), Vector2(1,0)],   [Vector2(1,1), Vector2(0,1)],
                [Vector2(1,-1), Vector2(1,0)],  [Vector2(1,-1), Vector2(0,-1)],
                [Vector2(-1,1), Vector2(-1,0)], [Vector2(-1,1), Vector2(0,1)],
                [Vector2(-1,-1), Vector2(-1,0)],[Vector2(-1,-1), Vector2(0,-1)]
        ]
        
        for arm in arms:
                var diag_pos = piece_position + arm[0]
                if is_valid_position(diag_pos) and is_empty(diag_pos):
                        var ortho_dir = arm[1]
                        var pos = diag_pos + ortho_dir
                        var step = 1
                        
                        while is_valid_position(pos):
                                if not is_empty(pos):
                                        if step >= 3 and is_enemy(pos):
                                                var temp = board[pos.x][pos.y]
                                                var self_piece = board[piece_position.x][piece_position.y]
                                                board[pos.x][pos.y] = self_piece
                                                board[piece_position.x][piece_position.y] = 0
                                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                                        _moves.append(pos)
                                                board[piece_position.x][piece_position.y] = self_piece
                                                board[pos.x][pos.y] = temp
                                        break 
                                else:
                                        if step >= 3:
                                                var tmp = board[pos.x][pos.y]
                                                board[pos.x][pos.y] = board[piece_position.x][piece_position.y]
                                                board[piece_position.x][piece_position.y] = 0
                                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                                        _moves.append(pos)
                                                board[piece_position.x][piece_position.y] = board[pos.x][pos.y]
                                                board[pos.x][pos.y] = tmp
                                pos += ortho_dir
                                step += 1
        return _moves

# GENERAL (Fers) - Moves exactly 1 square diagonally
func get_general_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(1,1), Vector2(1,-1), Vector2(-1,1), Vector2(-1,-1)]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves

# VIZIER (Wazir) - Moves exactly 1 square orthogonally
func get_vizier_moves(piece_position: Vector2):
        var _moves = []
        var directions = [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]
        for dir in directions:
                var pos = piece_position + dir
                if is_valid_position(pos):
                        if is_empty(pos) or is_enemy(pos):
                                var temp = board[pos.x][pos.y]
                                var s = board[piece_position.x][piece_position.y]
                                board[pos.x][pos.y] = s
                                board[piece_position.x][piece_position.y] = 0
                                if (white and not is_in_check(white_king_pos)) or (not white and not is_in_check(black_king_pos)):
                                        _moves.append(pos)
                                board[piece_position.x][piece_position.y] = s
                                board[pos.x][pos.y] = temp
        return _moves


# ------------------------------- HELPER FUNCTIONS --------------------

func is_valid_position(pos: Vector2) -> bool:
        return pos.x >= 0 and pos.x < BOARD_LENGTH and pos.y >= 0 and pos.y < BOARD_WIDTH

func is_empty(pos: Vector2) -> bool:
        return board[pos.x][pos.y] == 0

func is_enemy(pos: Vector2) -> bool:
        var piece = board[pos.x][pos.y]
        if piece == 0:
                return false
        # If it's white's turn, an enemy is negative. If black's turn, enemy is positive.
        return (white and piece < 0) or (not white and piece > 0)

func is_in_check(king_pos: Vector2) -> bool:
        # NOTE: Needs actual logic to iterate through enemy pieces and check their attack lines against the king
        return false

func threefold_position(current_board: Array):
        pass # Add your threefold repetition tracking here

func is_stalemate() -> bool:
        # Needs logic to iterate over all current player pieces and see if get_moves returns > 0 moves
        return false

func insufficient_material() -> bool:
        return false

func _on_button_pressed(button):
        pass
