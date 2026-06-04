class_name StateMachine

extends Node

@export var CURRENT_STATE: State
var states: Dictionary = {}

func _ready() -> void :
    for child in get_children():
        if child is State:
            states[child.name] = child
            child.transition.connect(on_child_transition)
        else:
            push_error("State machine contains incompatible child node")

    await owner.ready
    print("CURRENT_STATE: ", CURRENT_STATE)
    CURRENT_STATE.enter()

func _process(delta):
    CURRENT_STATE.update(delta)

func _physics_process(delta):
    CURRENT_STATE.physics_update(delta)

func on_child_transition(new_state_name: StringName) -> void :
    var new_state = states.get(new_state_name)
    if new_state != null:
        if new_state != CURRENT_STATE:
            CURRENT_STATE.exit()
            new_state.enter()
            CURRENT_STATE = new_state
    else:
        push_error("State: ", new_state_name, ", does not exist")

func _input(event: InputEvent) -> void :
    if CURRENT_STATE and CURRENT_STATE.has_method("handle_input"):
        CURRENT_STATE.handle_input(event)
