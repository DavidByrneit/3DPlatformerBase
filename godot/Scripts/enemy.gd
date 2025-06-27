extends CharacterBody3D

# Get a reference to the NavigationAgent3D node
@onready
var navAgent:NavigationAgent3D = $NavigationAgent3D

## Player to attack and chase
@export var Player:Node3D
@export var chase_distance:=5
# Get a reference to the AnimationPlayer node
@onready
var animationPlayer:AnimationPlayer = $Enemy/AnimationPlayer

# Physics process function, runs every physics frame
func _physics_process(_delta: float) -> void:
	# Set the navigation agent's target position to the player's position
	navAgent.target_position = Player.position
	
	# Check if the enemy is within 5 units of the player
	if navAgent.distance_to_target() < chase_distance:
		# If the animation is not already playing, play the "Walk" animation
		if !animationPlayer.is_playing():
			animationPlayer.play("Walk")
		
		# Get the next position along the navigation path
		var navAgentDestination = navAgent.get_next_path_position()
		
		# Make the enemy look at the player (negative sign used to correct orientation)
		self.look_at(-Player.position)
		
		# Calculate movement direction based on navigation
		var localDestination = navAgentDestination - global_position
		var direction = localDestination.normalized()
		
		# Apply movement velocity to the enemy
		velocity = direction * 4.0
		move_and_slide()
		
		# If very close to the player, play the attack animation
		if navAgent.distance_to_target() < 2:
			animationPlayer.play("Bite_Front")


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Attack"):
		queue_free()
