# REQUIREMENTS

## Must have:
### car
[x] accelerates
[X] collides
[X] different skins
[x] sfx
### tracks (at least one)
[x] design
[x] colliders
[x] lap registration (including total time registration)
### game
[x] time trial game mode
[x] music
[x] credits section with url to opengameart

## Nice to have
[] race mode against AI
[] ghost silhouette for time trial mode

## Experimental
[] Dynamic acceleration:
	func compute_dynamic_accel() -> float:
	'''
	Function that computes acceleration based on a nomalized beta-like
	distribution function
	'''
	var x = (body.velocity.length() / max_speed)
	x = max(0.1, x)
	var shape = (x ** alpha_accel) * ((1 - x) ** beta_accel)
	# get the maximum x value to normalize to guarantee the maximum is always max_accel
	var peak_x = alpha_accel / (alpha_accel + beta_accel)
	var peak_val = (peak_x ** alpha_accel) * ((1 - peak_x) ** beta_accel)
	
	return max_accel * shape / peak_val
	
