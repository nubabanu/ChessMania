extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func generate_fischer_random_row() -> Array:
	# We’ll generate permutations of indices [0..7] that map to pieces:
	# [ R, N, B, Q, K, B, N, R ] => [4,2,3,5,6,3,2,4]
	var base_pieces = [4, 2, 3, 5, 6, 3, 2, 4]  # White side representation
	var valid_setups = []
	
	# Generate all permutations of base_pieces:
	var all_permutations = permute_array(base_pieces)
	
	for perm in all_permutations:
		# perm is something like [2,4,3,5,6,3,2,4] etc.
		if is_valid_chess960(perm):
			valid_setups.append(perm)
	
	# Pick a random valid arrangement
	if valid_setups.size() > 0:
		var idx = randi() % valid_setups.size()
		return valid_setups[idx]
	else:
		# Fallback: in theory should never happen if coded correctly
		return base_pieces


func permute_array(arr: Array) -> Array:
	# Simple way to get permutations of an Array in GDScript
	if arr.size() <= 1:
		return [arr.duplicate()]
	var result = []
	for i in range(arr.size()):
		var first = arr[i]
		var remainder = arr.duplicate()
		remainder.remove_at(i)
		var perms_of_rest = permute_array(remainder)
		for p in perms_of_rest:
			var new_p = [first] + p
			result.append(new_p)
	return result


func is_valid_chess960(arr: Array) -> bool:
	# arr: 8-element array, e.g. [4,2,3,5,6,3,2,4]
	# 1) Bishops must be on opposite colors
	#    Indices (0..7) that are even => dark squares, odd => light squares (or vice-versa)
	#    We check the positions of the bishops (value == 3).
	var bishop_positions = []
	for i in range(arr.size()):
		if abs(arr[i]) == 3:
			bishop_positions.append(i)
	if bishop_positions.size() != 2:
		return false
	# Are these on opposite color squares?
	# One must be even index, the other odd index
	if bishop_positions[0] % 2 == bishop_positions[1] % 2:
		return false
	
	# 2) King must be *between* the two rooks
	#    So if the rooks are at positions r1 and r2 and the king at k,
	#    we need min(r1,r2) < k < max(r1,r2).
	var rook_positions = []
	var king_position = -1
	for i in range(arr.size()):
		if abs(arr[i]) == 4:  # Rook
			rook_positions.append(i)
		elif abs(arr[i]) == 6:  # King
			king_position = i
	
	# We must have exactly 2 rooks, 1 king in the array
	if rook_positions.size() != 2 or king_position == -1:
		return false
	
	var rmin = min(rook_positions[0], rook_positions[1])
	var rmax = max(rook_positions[0], rook_positions[1])
	if not(rmin < king_position and king_position < rmax):
		return false
	
	return true
