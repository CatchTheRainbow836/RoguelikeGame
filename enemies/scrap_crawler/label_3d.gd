extends Label3D

@onready var enemy_state_machine: StateMachine = $"../EnemyStateMachine"
@onready var attack_state_machine: StateMachine = $"../AttackStateMachine"
@onready var scrap_crawler: ScrapCrawler = $".."
@onready var control_center = $"../EnemyControlCenter"

func _process(delta: float) -> void:
	if not control_center:
		text = "Scrap Crawler\n(no control centre)"
		return
	text = "Scrap Crawler\n" \
		+ enemy_state_machine.CURRENT_STATE.name + "\n" \
		+ attack_state_machine.CURRENT_STATE.name + "\n" \
		+ "AI: " + control_center.ai_state_string() + "\n" \
		+ "can_see: " + str(control_center.can_see_player()) + "\n" \
		+ "alert: " + str(control_center.last_alert_strength)
