Config.title = ['SPRINGING']
#Config.isDebuggingMode = true

window.initialize = ->
	Sound.sd 4321
	@drums = []
	@drums.push G.ns.d().dp() for i in [1..4]
window.begin = ->
	d.pp for d in @drums
	new Spring if G.ib
	for i in [1..20]
		f = new Floor
		f.p.xy i * .05 - .025, 1 - .025
	@scf = G.nf
		.dr ->
			@n if @cn <= 0
		.d ->
			addFloors @cn
			@cn += 1
	@scf.cn = 0
	@asc = G.nf
		.dr ->
			@n if @cn <= 0
		.d ->
			G.sc++ if G.ib
			@cn += .1
	@asc.cn = .1
	@scy = 0
	@mpn = 0
	Bonus.sc = 100
	new Bonus
	new Build for i in [1..9]
window.update = ->
	bs = G.df 2, 3
	if G.ib && M.ip
		if @mpn < 60
			@scy += (.05 * bs - @scy) * .05
			@mpn++
		else
			@scy += (.005 * bs - @scy) * .1
	else
		@scy += (.005 * bs - @scy) * .1
		@mpn-- if @mpn > 0
	scroll @scy
	if G.ib && G.t == 0
		G.nt '[CLICK / TOUCH] ACCEL'
			.xy .1, .1
			.d 250
			.al
			.so
scroll = (scy) ->
	A.sc [Floor, Bonus], -scy
	A.sc Build, -scy / 2, 0, -.5, 1.5
	@scf.cn -= scy
	@asc.cn -= scy
addFloors = (ox) ->
	ox += 1
	spc = 0
	for i in [1..20]
		spc = 2.rri 4 if spc <= 0 && (1.rri 7) == 1
		if spc-- <= 0
			f = new Floor
			f.p.xy i * .05 - .025 + ox, 1 - .025
	fn = 1.rri 3
	for i in [1..fn]
		x = 1.rri 20
		y = 10.rri 18
		n = 3.rri 7
		for j in [1..n]
			f = new Floor
			f.p.xy x * .05 - .025 + ox, y * .05 - .025
			x += 1
class Spring extends A
	i: ->
		Spring.bs = @ns.v(4).d()
		Spring.ds = @ns.v(7).d()
	b: ->
		@d
			.c C.y
			.rs .04, .01, 0, .015
			.rt 360 / 3, 2
		@p.xy .1, .5
		@sy = 1
		@vsy = 0
	u: ->
		@v.y += .002
		@spr() if @v.y > 0 && @oc Floor
		@vsy += (1 - @sy) * .1
		@vsy *= .95
		@sy += @vsy
		@d.sc 1, @sy
		if @p.y > 1 && @v.y > 0
			Spring.ds.pn
			@np
				.w 0, 90
				.s .05
				.sz .05
				.n 20
			@r
			G.e
	spr: ->
		Spring.bs.p
		@v.y = -.033
		@sy = .5
class Floor extends A
	b: ->
		@d
			.c C.g
			.r .04
	u: ->
		@r if @p.x < -.025
class Bonus extends A
	i: ->
		Bonus.gs = @ns.v(4).d()
	b: ->
		@d
			.c C.y
			.r .03, .03, .04
			.rt 360 / 5, 4
		@p.xy 1.025, (.4.rr .8)
	u: ->
		@w += 13
		@nt "+#{Bonus.sc}"
			.xy @p.x, @p.y - .07
		if @oc Spring, ((s) -> s.spr())
			Bonus.gs.p
			@np
				.c C.y
				.n 5
			@nt "+#{Bonus.sc}"
				.xy @p.x, @p.y - .07
				.v 0, -.1
				.d 60
			G.sc += Bonus.sc
			@r
			Bonus.sc += 100 if Bonus.sc < 1000
			new Bonus
		if @p.x < -.025
			@r
			Bonus.sc -= 100 if Bonus.sc > 100
			new Bonus
class Build extends A
	i: ->
		@dp .5
	b: ->
		w = .1.rr .3
		h = .4.rr .8
		@d
			.r w, .003, 0, -h
			.r .003, h, -w / 2, -h / 2
			.mx
		@p.xy ((-.5).rr 1.5), 1
