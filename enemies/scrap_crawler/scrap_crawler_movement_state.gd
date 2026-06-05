extends DefaultEnemyMovementState
class_name ScrapCrawlerMovementState

var crawler: ScrapCrawler

func _ready() -> void :
	super._ready()
	await owner.ready
	crawler = owner as ScrapCrawler
	if crawler:
		speed = crawler.speed
		accel = crawler.accel
		wander_radius = crawler.wander_radius
		view_distance = crawler.view_distance
		fov_degrees = crawler.fov_degrees
