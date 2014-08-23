MGL.COFFEE (Mini Game programming Library in CoffeeScript)
======================
MGL.COFFEE is a mini game programming library written in [CoffeeScript](http://coffeescript.org/). MGL.COFFEE is useful for creating a simple HTML5 game in short term.

Using the [jsfx](https://github.com/egonelbre/jsfx) sound effect generator.

Using the [jsgif](https://github.com/antimatter15/jsgif) animated gif encoder.

### How to create

* this game: [CHARGE RUSH](http://abagames.sakura.ne.jp/html5/cr/)

* less than 1 hour, probably, perhaps.

![cr_capture](http://abagames.sakura.ne.jp/html5/cr/cr_capture.gif)

* Download the zip file and unzip.

* Open 'index.html' with any text editor.

* See the script on line 54. This is the template code for MGL.COFFEE.

```coffee
Config.title = ['MGL.', 'COFFEE']
#Config.isDebuggingMode = true

window.initialize = ->
window.begin = ->
window.update = ->
```

* Set `Config.title` to any title name you like.

* Uncomment `Config.isDebuggingMode = true` to skip the title screen for debugging.

```coffee
Config.title = ['CHARGE', 'RUSH']
Config.isDebuggingMode = true
```

* Create `Ship` class .It's a player's ship controlled by the mouse.

```coffee
# characters in the game is called actor
# class of actor should be extended from 'Actor' class
class Ship extends Actor
	# 'begin' function is called once when the actor is created
	begin: ->
		# 'addRect' to '@drawing' for creating the actor's shape
		@drawing
			.setColor Color.white
			# 'addRect' args: width, height, offsetX, offsetY
			.addRect 0.02, 0.05, 0, -0.01
			.setColor Color.red
			.addRect 0.02, 0.04, -0.02, 0
			.addRect 0.02, 0.04, 0.02, 0
	# 'update' function is called every frame
	update: ->
		# '@pos' represents the position of the actor
		# 'Mouse.pos' is the position of the mouse cursor 
		@pos.setValue Mouse.pos
```

* Add `new Ship` at `window.begin` function.

```coffee
# 'window.begin' function is called once when the game starts
window.begin = ->
	new Ship
```

* Open 'index.html' with the browser (Chrome or Firefox is reocommended) and check the behavior.

![cr_capture_1](http://abagames.sakura.ne.jp/html5/cr/cr_capture_1.gif)

* Create Ship's `Shot` class.

```coffee
class Shot extends Actor
	# arguments of 'begin' function are passed from
	# the constructor of this actor
	begin: (p) ->
		@drawing
			.setColor Color.red
			.addRect 0.02, 0.03, -0.02, 0
			.addRect 0.02, 0.03, 0.02, 0
		@pos.setValue p
		# set the velocity ('@vel') to the upper direction
		@vel.y = -0.03
	update: ->
		# remove this actor when the position isn't in the screen
		#  the position of the screen:
		#   upper-left (0, 0)----(1, 0) upper-right
		#                   |    |
		#   lower-left (0, 1)----(1, 1) lower-right
		@remove() if !@pos.isIn()
```

* Use `Fiber` to add the shot every 5 frames.

```coffee
class Ship extends Actor
....
	begin: ->
....
		# '@newFiber' function create 'Fiber' assigned to this actor
		@newFiber()
			# 'doOnce' creating 'Shot' instance
			.doOnce =>
				new Shot @pos
			# 'wait' 3 frames and back to 'doOnce' procedure
			.wait 3
```

* Add the muzzle flash effect with 'Particle' when the shot is fired.

```coffee
class Shot extends Actor
....
	begin: ->
....
		@addMuzzleFlash -0.02
		@addMuzzleFlash 0.02
	addMuzzleFlash: (offsetX) ->
		@newParticle()
			.setXy @pos.x + offsetX, @pos.y
			.setColor Color.red
			# set the number of particles emitted
			.setNumber 3
			# 'setWay' args:
			#  center angle (degree, clockwise), scattering angle
			.setWay 0, 30
			.setSpeed 0.03
			# set the duration until the particle disappears
			.setDuration 3
```

![cr_capture_2](http://abagames.sakura.ne.jp/html5/cr/cr_capture_2.gif)

* Create `Enemy` class.

```coffee
class Enemy extends Actor
	begin: (y, vy) ->
		@drawing
			.setColor Color.yellow
			.addRect 0.03, 0.05, 0, 0.01
			.addRect 0.02, 0.04, -0.03, 0
			.addRect 0.02, 0.04, 0.03, 0
		# 'A.rr B' creates a random number from A to B 
		@pos.setXy (0.1.rr 0.9), y
		@vel.y = vy
	update: ->
		@remove() if @pos.y > 1
```

* Create a fiber to add enemies.

```coffee
window.begin = ->
....
	# 'Game.newFiber' function creates a fiber assigned to this game
	Game.newFiber()
		.doOnce ->
			# 'Game.getDifficulty' function returns the number
			# represents the difficulty increasing with the time passed
			#  1 (game starts) -> 2 (about 3 minutes passed) ->
			ev = (0.01.rr 0.02) * Game.getDifficulty()
			for y in [1..9]
				new Enemy -y * 0.1, ev
		# repeat until '@next' function is called
		.doRepeat ->
			# 'Actor.s' function returns all actors of
			# the class specifiled at the argument
			@next() if (Actor.s Enemy).length == 0
```

* Enemy should be destroyed when it collides the player's shot.

```coffee
class Enemy extends Actor
...
	update: ->
		# '@onCollision' function returns true when
		# this actor collides actors of the specific class
		#  args: specific class, function called with the colliding actor
		if @onCollision Shot, ((shot) -> shot.remove())
			@newParticle()
				.setColor Color.yellow
				.setNumber 5
			@remove()
```

![cr_capture_3](http://abagames.sakura.ne.jp/html5/cr/cr_capture_3.gif)

* Create `Bullet` class fired by the enemy.

```coffee
class Bullet extends Actor
	begin: (p) ->
		@pos.setValue p
		ship = (Actor.s Ship)[0]
		# remove when the firing position is too close to the ship
		if !ship? || !@pos.ii || (@pos.distanceTo ship.pos) < 0.3
			@remove()
			return
		# if an actor has to rotate, use 'addRects' function that
		# adds separated squares for a rectangle
		@drawing
			.addRects 0.04, 0.02
			.addRects 0.02, 0.04
		# get an angle to the ship
		angle = @pos.wayTo ship.pos
		speed = (0.005.rr 0.015) * Game.getDifficulty()
		@vel.addWay angle, speed
		@newParticle()
			.setNumber 3
			.setWay angle, 10
			.setSpeed speed * 2
			.setDuration 5
	update: ->
		# rotate this actor
		@way += 7
		# the argument of 'isIn' function means a spacing value
		# in this case 'isIn' returns true when -0.05 < x and y < 1.05
		@remove() if !@pos.isIn 0.05
```

* Add a fiber for firing bullets.

```coffee
class Enemy extends Actor
	begin: (y, vy) ->
....
		@newFiber()
			.doOnce =>
				new Bullet @pos
			.wait 30 / Game.getDifficulty()
```

* Implement a scoring system. First, count up a stage number when enemies appear.

```coffee
window.begin = ->
...
	Game.stage = 0
...
	Game.newFiber()
		.doOnce ->
			Game.stage++
```

* Then add a score according to the stage number when an enemy is destroyed.

```coffee
class Enemy extends Actor
....
	update: ->
....
		if @onCollision Shot, ((shot) -> shot.remove())
			# add score only when the game is beginning
			if Game.isBeginning
				score = Game.stage * 10
				# '@newText' function show the text to the screen
				@newText "+#{score}"
					.setVelocity 0, -0.1
					.setDuration 30
				Game.score += score
```

* Player can earn a score also when a shot hits a bullet.

```coffee
class Shot extends Actor
....
	update: ->
....
		if Game.isBeginning && @onCollision Bullet
			score = Game.stage
			@newText "+#{score}"
				.setVelocity 0, -0.03
				.setDuration 10
			Game.score += score
```

![cr_capture_4](http://abagames.sakura.ne.jp/html5/cr/cr_capture_4.gif)

* Create 'Star' class for stars on a background.

```coffee
class Star extends Actor
	# 'initialize' function is called only once when
	# the first actor is created
	initialize: ->
		# the actor has the lower display priority number is
		# displayed below actors have the higher number
		#  0 (particle) -> 1 (default number for an actor) -> 2 (text)
		@setDisplayPriority 0.5
	begin: ->
		@drawing
			# 'addRect' add a square when the second argument is skipped
			.addRect 0.01
		@pos.setXy (0.rr 1), (0.rr 1)
```

* Add stars and scroll them.

```coffee
window.begin = ->
....
		new Star for i in [1..30]
# 'window.update' function is called every frame
window.update = ->
	# 'Actor.scroll' args:
	#   target class(es), velocityX, velocityY, minX, maxX, minY, maxY
	#  y becomes minY when y > maxY and vice versa
	Actor.scroll Star, 0, 0.002, 0, 0, 0, 1
```

* Add the bgm drum patterns. Try changing the random seed of `Sound` class until the proper sound is generated.

```coffee
# 'window.initialize' function is called only once when
# the window is loaded
window.initialize = ->
	# Set the 'Sound' class random seed for auto generated sounds
	Sound.setSeed 1234
	@drums = []
	# 'setDrum' and 'setDrumPattern' functions create
	# a random drum voice and pattern when no arg is provided
	@drums.push Game.newSound().setDrum().setDrumPattern() for i in [1..4]
....
window.begin = ->
	drum.playPattern() for drum in @drums
```

* Add sound effects with auto generated drum voices.

```coffee
class Enemy extends Actor
	initialize: ->
		Enemy.destroySe = @newSound().setDrum()
....
	update: ->
....
		if @onCollision Shot, ((shot) -> shot.remove())
			# 'play' function plays the quantized sound
			Enemy.destroySe.play()
```

```coffee
class Bullet extends Actor
	initialize: ->
		Bullet.shotSe = @newSound().setDrum()
	begin: (p) ->
....
		Bullet.shotSe.play()
```

* Finally, implement the game over. Player's ship must be destroyed when it hits a bullet or en enemy.

```coffee
class Ship extends Actor
	initialize: ->
		# since default volume value of the sound is 1
		# this sound effect becomes louder
		Ship.destroySe = @newSound().setVolume(3).setDrum()
....
	update: ->
....
		@destroy() if @onCollision Bullet
		@destroy() if @onCollision Enemy
	destroy: ->
		@newParticle()
			.setColor Color.red
			.setSize 0.1
			.setNumber 20
			.setSpeed 0.05
		# 'playNow' function plays the sound without quantizing
		Ship.destroySe.playNow()
		@remove()
		# back to the title screen when 'Game.end' function is called
		Game.end()
```

![cr_capture_5](http://abagames.sakura.ne.jp/html5/cr/cr_capture_5.gif)

* Comment out `Config.isDebuggingMode = true`. 

```coffee
#Config.isDebuggingMode = true
```

* Since 'window.begin' function is also called before the title screen, a ship should be added only when the game is beginning.

```coffee
window.begin = ->
....
	# Add the ship when the game is beginning
	new Ship if Game.isBeginning
```

* Add the instruction text displayed after the game starts.

```coffee
window.update = ->
....
	# 'Game.ticks' means a frame count from a beginning of a game
	if Game.isBeginning && Game.ticks == 0
		Game.newText '[MOUSE] MOVE'
			.setXy 0.1, 0.1
			.setDuration 250
			.alignLeft()
			# if 'showOnce' function is called, this text is
			# shown only once after the window is loaded
			.showOnce()
```

* Finished!

### Short abbreviated class/mehod names

You can use short abbreviated class/method names. See [SPRINGING](./samples/springing.coffee) sample.

### Capture a screenshot

* Add `Config.captureArgs`.

```coffee
# args: scale, duration (sec), interval (sec)
Config.captureArgs = [0.5, 3, 0.05]
```

* Open the html file with a browser.

* Press 'c' key to capture a screenshot with an animated gif.

License
----------
Copyright &copy; 2014 ABA Games

Distributed under the [MIT License][MIT].

[MIT]: http://www.opensource.org/licenses/mit-license.php
