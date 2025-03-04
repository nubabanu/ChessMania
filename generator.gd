extends FlowContainer

@export var BoardXSize = 8
@export var BoardYSize = 8

@export var TileXSize: float = 50
@export var TileYSize: float = 50

signal SendLocation(Location: String)

@export var Pawn: PackedScene
@export var Bishop: PackedScene
@export var Rook: PackedScene
@export var Knight: PackedScene
@export var Queen: PackedScene
@export var King: PackedScene

func _ready():
	if BoardXSize < 0 || BoardYSize < 0:
		return
	var NumberX: int = 0
	var NumberY: int = 0
	while NumberY != BoardYSize:
		self.size.y += TileYSize + 5
		self.size.x += TileXSize + 5
		while NumberX != BoardXSize:
			var temp = Button.new()
			temp.set_custom_minimum_size(Vector2(TileXSize, TileYSize))
			temp.connect("pressed", func():
				SendLocation.emit(temp.name))
			temp.set_name(str(NumberX) + "-" + str(NumberY))
			add_child(temp)
			NumberX += 1
		NumberY += 1
		NumberX = 0
	if GameSettings.PlayRegularGame:
		RegularGame()
	else:
		FischerRandomGame()

func RegularGame():
	get_node("0-0").add_child(Summon(Rook, 1))
	get_node("1-0").add_child(Summon(Knight, 1))
	get_node("2-0").add_child(Summon(Bishop, 1))
	get_node("3-0").add_child(Summon(Queen, 1))
	get_node("4-0").add_child(Summon(King, 1))
	get_node("5-0").add_child(Summon(Bishop, 1))
	get_node("6-0").add_child(Summon(Knight, 1))
	get_node("7-0").add_child(Summon(Rook, 1))
	for i in range(8):
		get_node(str(i) + "-1").add_child(Summon(Pawn, 1))
	for i in range(8):
		get_node(str(i) + "-6").add_child(Summon(Pawn, 0))
	get_node("0-7").add_child(Summon(Rook, 0))
	get_node("1-7").add_child(Summon(Knight, 0))
	get_node("2-7").add_child(Summon(Bishop, 0))
	get_node("3-7").add_child(Summon(Queen, 0))
	get_node("4-7").add_child(Summon(King, 0))
	get_node("5-7").add_child(Summon(Bishop, 0))
	get_node("6-7").add_child(Summon(Knight, 0))
	get_node("7-7").add_child(Summon(Rook, 0))

func FischerRandomGame():
	var positions = [Rook, Knight, Bishop, Bishop, Queen, Knight, Rook, King]
	positions.shuffle()
	while positions.find(Bishop, 0) % 2 == positions.find(Bishop, 1) % 2:
		positions.shuffle()
	while positions.find(King) < positions.find(Rook, 0) or positions.find(King) > positions.find(Rook, 1):
		positions.shuffle()
	for i in range(8):
		get_node(str(i) + "-0").add_child(Summon(positions[i], 1))
		get_node(str(i) + "-7").add_child(Summon(positions[i], 0))
	for i in range(8):
		get_node(str(i) + "-1").add_child(Summon(Pawn, 1))
		get_node(str(i) + "-6").add_child(Summon(Pawn, 0))

func Summon(Scene: PackedScene, color: int):
	var Piece = Scene.instantiate()
	Piece.Spawned(color)
	Piece.position = Vector2(TileXSize / 2, TileYSize / 2)
	return Piece
