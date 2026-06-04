extends StaticBody3D
class_name ElevatorButton

signal died

func take_damage(amount: float):
    died.emit()
    queue_free()
