extends ItemData
class_name ConsumableItem

@export var health_bonus: int = 10

# We override the base function
func use(player: Node) -> bool:
	# Check if the player has a "health" variable (we will add this next)
	if "health" in player:
		player.health += health_bonus
		print("Used " + name + ". Health is now: " + str(player.health))
		return true # Return true means "Destroy this item after use"
	
	return false
	
