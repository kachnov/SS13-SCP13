GLOBAL_LIST_EMPTY(scp173s)

/datum/scp/SCP_173
	name = "SCP-173"
	designation = "173"
	classification = EUCLID

/mob/living/scp_173
	name = "SCP-173"
	desc = "A statue, constructed from concrete and rebar with traces of Krylon brand spray paint"
	icon = 'icons/SCP/scp-173.dmi'
	icon_state = "173"
	SCP = /datum/scp/SCP_173

	maxHealth = 5000
	health = 5000

	var/last_snap = 0
	var/next_shit = 0
	var/list/next_blinks = list()

	var/last_player_shit = 0

/mob/living/scp_173/examine(mob/user)
	user << "<b><span class = 'euclid'><big>SCP-173</big></span></b> - [desc]"

/mob/living/scp_173/New()
	..()
	GLOB.scp173s += src
	verbs += /mob/living/proc/ventcrawl
	add_language(LANGUAGE_GALCOM, 1) // it's a fucking magical statue
	add_language(LANGUAGE_EAL, 1)
	add_language(LANGUAGE_SOL_COMMON, 1)
	add_language(LANGUAGE_UNATHI, 1)
	add_language(LANGUAGE_SIIK_MAAS, 1)
	add_language(LANGUAGE_SKRELLIAN, 1)
	add_language(LANGUAGE_LUNAR, 1)
	add_language(LANGUAGE_GUTTER, 1)
	add_language(LANGUAGE_SIGN, 0)
	add_language(LANGUAGE_INDEPENDENT, 1)
	add_language(LANGUAGE_SPACER, 1)

/mob/living/scp_173/Destroy()
	GLOB.scp173s -= src
	..()

/mob/living/scp_173/say(var/message)
	return // lol you can't talk

/mob/living/scp_173/proc/IsBeingWatched()
	// Am I being watched by eye pals?
	for (var/mob/living/M in view(src, 7))
		if ((istype(M, /mob/living/simple_animal/scp_131)) && (InCone(M, M.dir)))
			return TRUE

	// Am I being watched by anyone else?
	for(var/mob/living/carbon/human/H in view(src, 7))
		if(H.SCP)
			continue
		if(is_blind(H) || H.eye_blind > 0)
			continue
		if(H.stat != CONSCIOUS)
			continue
		if(next_blinks[H] == null)
			next_blinks[H] = world.time+rand(25 SECONDS, 45 SECONDS)
		if(InCone(H, H.dir))
			return TRUE
	return FALSE

/mob/living/scp_173/Move(a,b,f)
	if(IsBeingWatched())
		return FALSE
	return ..(a,b,f)

/mob/living/scp_173/movement_delay()
	return -5

/mob/living/scp_173/UnarmedAttack(var/atom/A)
	if(!IsBeingWatched() && ishuman(A))
		var/mob/living/carbon/human/H = A
		if(H.SCP)
			to_chat(src, "<span class='warning'><I>[H] is a fellow SCP!</I></span>")
			return
		if(H.stat == DEAD)
			to_chat(src, "<span class='warning'><I>[H] is already dead!</I></span>")
			return
		visible_message("<span class='danger'>[src] snaps [H]'s neck!</span>")
		playsound(loc, pick('sound/scp/spook/NeckSnap1.ogg', 'sound/scp/spook/NeckSnap3.ogg'), 50, 1)
		H.death()
		H.scp173_killed = TRUE

/mob/living/scp_173/Life()
	. = ..()
	if (isobj(loc))
		return
	var/list/our_view = view(src, 7)
	for(var/A in next_blinks)
		if(!(A in our_view))
			next_blinks[A] = null
			continue
		if(world.time >= next_blinks[A])
			var/mob/living/carbon/human/H = A
			if(H.stat) // Sleeping or dead people can't blink!
				next_blinks[A] = null
				continue
			H.visible_message("<span class='notice'>[H] blinks.</span>")
			H.eye_blind += 2
			next_blinks[H] = 10+world.time+rand(25 SECONDS, 45 SECONDS)
	if(client)
		return
	if(IsBeingWatched())
		return
	if(world.time >= next_shit)
		next_shit = world.time+rand(5 MINUTES, 10 MINUTES)
		var/feces = pick(/obj/effect/decal/cleanable/blood, /obj/effect/decal/cleanable/blood/gibs, /obj/effect/decal/cleanable/mucus)
		new feces(loc)
		return
	var/mob/living/carbon/human/target
	var/mob/living/carbon/human/possible_targets = list(null)
	for(var/mob/living/carbon/human/H in our_view)
		if(H.SCP)
			continue
		if(H.stat == DEAD)
			continue
		if(!AStar(loc, H.loc, /turf/proc/AdjacentTurfs, /turf/proc/Distance, max_nodes=25, max_node_depth=7))
			continue // We can't reach this person anyways
		possible_targets += H
	if(world.time >= last_snap+50)
		var/turf/spot
		target = pick(possible_targets)
		if (target)
			var/turf/behind_target = get_step(target.loc, turn(target.dir, 180))
			if(isfloor(behind_target) && get_dist(behind_target, loc) <= 7)
				spot = behind_target
			else
				var/list/directions = shuffle(GLOB.cardinal.Copy())
				for(var/D in directions)
					var/turf/T = get_step(target, D)
					if(isfloor(T) && get_dist(T, loc) <= 7)
						spot = T
						break
			if(!spot) // We couldn't find a spot to go to!
				return
			forceMove(spot)
			dir = get_dir(src, target)
			visible_message("<span class='danger'>[src] snaps [target]'s neck!</span>")
			playsound(loc, pick('sound/scp/spook/NeckSnap1.ogg', 'sound/scp/spook/NeckSnap3.ogg'), 50, 1)
			target.death()
			target.scp173_killed = TRUE
			last_snap = world.time

/mob/living/scp_173/can_ventcrawl()
	if(IsBeingWatched())
		to_chat(src, "<span class='warning'>You're being watched!</span>")
		return FALSE
	return ..()

/mob/living/scp_173/verb/get_schwifty() // plz don't kill me for the reference
	set name = "Shit On Floor"
	set category = "SCP"
	if(!isobj(loc) && world.time >= (last_player_shit + 600))
		last_player_shit = world.time
		var/feces = pick(/obj/effect/decal/cleanable/blood, /obj/effect/decal/cleanable/blood/gibs, /obj/effect/decal/cleanable/mucus)
		new feces(loc)

// humans 
/mob/living/carbon/human/set_stat(_new)
	..(_new)
	if (stat != DEAD)
		scp173_killed = FALSE

// the cage
/obj/structure/scp173_cage
	icon = 'icons/SCP/cage.dmi'
	icon_state = "1"
	layer = MOB_LAYER + 0.01
	name = "Empty SCP-173 Cage"

/obj/structure/scp173_cage/MouseDrop_T(atom/movable/dropping, mob/user)
	if (isscp173(dropping))
		visible_message("<span class = \"danger\">[user] starts to put SCP-173 into the cage.</span>")
		var/oloc = loc
		if (do_mob(user, dropping, 5 SECONDS) && loc == oloc) // shitty but there's no good alternative
			dropping.forceMove(src)
			underlays = list(dropping)
			overlays = list(src) // fuck me
			visible_message("<span class = \"good\">[user] puts SCP-173 in the cage.</span>")
			name = "SCP-173 Cage"
	else if (isliving(dropping))
		to_chat(user, "<span class = \"warning\">\The [dropping] won't fit in the cage.</span>")

/obj/structure/scp173_cage/attack_hand(mob/living/carbon/human/H)
	if (locate(/mob/living/scp_173) in contents)
		visible_message("<span class = \"danger\">[H] releases SCP-173 from the cage.</span>")

		var/mob/living/scp_173/S = contents[1]
		S.forceMove(get_step(src, dir))

		// move to a nice spot if our current one is too full
		for (var/dir in list(NORTH, EAST, SOUTH, WEST))
			if (S.loc.density || (locate(/mob/living) in (S.loc.contents-S)) || (locate(/obj/structure) in (S.loc.contents-S)))
				S.forceMove(get_step(src, dir))
			else
				break

		underlays.Cut()
		overlays.Cut()
		name = initial(name)
	else
		visible_message("<span class = \"warning\">The cage is empty; there's nothing to take out.</span>")