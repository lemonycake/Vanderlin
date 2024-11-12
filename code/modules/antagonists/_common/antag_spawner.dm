/obj/item/antag_spawner
	throw_speed = 1
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	var/used = FALSE

/obj/item/antag_spawner/proc/spawn_antag(client/C, turf/T, kind = "", datum/mind/user)
	return

/obj/item/antag_spawner/proc/equip_antag(mob/target)
	return


///////////WIZARD

/obj/item/antag_spawner/contract
	name = "contract"
	desc = ""
	icon = 'icons/obj/wizard.dmi'
	icon_state ="scroll2"

/obj/item/antag_spawner/contract/attack_self(mob/user)
	user.set_machine(src)
	var/dat
	if(used)
		dat = "<B>I have already summoned my apprentice.</B><BR>"
	else
		dat = "<B>Contract of Apprenticeship:</B><BR>"
		dat += "<I>Using this contract, you may summon an apprentice to aid you on my mission.</I><BR>"
		dat += "<I>If you are unable to establish contact with my apprentice, you can feed the contract back to the spellbook to refund my points.</I><BR>"
		dat += "<B>Which school of magic is my apprentice studying?:</B><BR>"
		dat += "<A href='byond://?src=[REF(src)];school=[APPRENTICE_DESTRUCTION]'>Destruction</A><BR>"
		dat += "<I>My apprentice is skilled in offensive magic. They know Magic Missile and Fireball.</I><BR>"
		dat += "<A href='byond://?src=[REF(src)];school=[APPRENTICE_BLUESPACE]'>Bluespace Manipulation</A><BR>"
		dat += "<I>My apprentice is able to defy physics, melting through solid objects and travelling great distances in the blink of an eye. They know Teleport and Ethereal Jaunt.</I><BR>"
		dat += "<A href='byond://?src=[REF(src)];school=[APPRENTICE_HEALING]'>Healing</A><BR>"
		dat += "<I>My apprentice is training to cast spells that will aid my survival. They know Forcewall and Charge and come with a Staff of Healing.</I><BR>"
		dat += "<A href='byond://?src=[REF(src)];school=[APPRENTICE_ROBELESS]'>Robeless</A><BR>"
		dat += "<I>My apprentice is training to cast spells without their robes. They know Knock and Mindswap.</I><BR>"
	user << browse(dat, "window=radio")
	onclose(user, "radio")
	return

/obj/item/antag_spawner/contract/Topic(href, href_list)
	..()
	var/mob/living/carbon/human/H = usr

	if(H.stat || H.restrained())
		return
	if(!ishuman(H))
		return 1

	if(loc == H || (in_range(src, H) && isturf(loc)))
		H.set_machine(src)
		if(href_list["school"])
			if(used)
				to_chat(H, "<span class='warning'>I already used this contract!</span>")
				return
			var/list/candidates = pollCandidatesForMob("Do you want to play as a wizard's [href_list["school"]] apprentice?", ROLE_WIZARD, null, ROLE_WIZARD, 150, src)
			if(LAZYLEN(candidates))
				if(QDELETED(src))
					return
				if(used)
					to_chat(H, "<span class='warning'>I already used this contract!</span>")
					return
				used = TRUE
				var/mob/dead/observer/C = pick(candidates)
				spawn_antag(C.client, get_turf(src), href_list["school"],H.mind)
			else
				to_chat(H, "<span class='warning'>Unable to reach my apprentice! You can either attack the spellbook with the contract to refund my points, or wait and try again later.</span>")

/obj/item/antag_spawner/contract/spawn_antag(client/C, turf/T, kind ,datum/mind/user)
	new /obj/effect/particle_effect/smoke(T)
	var/mob/living/carbon/human/M = new/mob/living/carbon/human(T)
	C.prefs.copy_to(M)
	M.key = C.key
	var/datum/mind/app_mind = M.mind

	var/datum/antagonist/wizard/apprentice/app = new()
	app.master = user
	app.school = kind

	var/datum/antagonist/wizard/master_wizard = user.has_antag_datum(/datum/antagonist/wizard)
	if(master_wizard)
		if(!master_wizard.wiz_team)
			master_wizard.create_wiz_team()
		app.wiz_team = master_wizard.wiz_team
		master_wizard.wiz_team.add_member(app_mind)
	app_mind.add_antag_datum(app)
	//TODO Kill these if possible
	app_mind.assigned_role = "Apprentice"
	app_mind.special_role = "apprentice"
	//
	SEND_SOUND(M, sound('sound/blank.ogg'))

///////////BORGS AND OPERATIVES


/obj/item/antag_spawner/nuke_ops
	name = "syndicate operative teleporter"
	desc = ""
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"
	var/borg_to_spawn

/obj/item/antag_spawner/nuke_ops/proc/check_usability(mob/user)
	if(used)
		to_chat(user, "<span class='warning'>[src] is out of power!</span>")
		return FALSE
	if(!user.mind.has_antag_datum(/datum/antagonist/nukeop,TRUE))
		to_chat(user, "<span class='danger'>AUTHENTICATION FAILURE. ACCESS DENIED.</span>")
		return FALSE
	if(!user.onSyndieBase())
		to_chat(user, "<span class='warning'>[src] is out of range! It can only be used at my base!</span>")
		return FALSE
	return TRUE


/obj/item/antag_spawner/nuke_ops/attack_self(mob/user)
	if(!(check_usability(user)))
		return

	to_chat(user, "<span class='notice'>I activate [src] and wait for confirmation.</span>")
	var/list/nuke_candidates = pollGhostCandidates("Do you want to play as a syndicate [borg_to_spawn ? "[lowertext(borg_to_spawn)] cyborg":"operative"]?", ROLE_OPERATIVE, null, ROLE_OPERATIVE, 150, POLL_IGNORE_SYNDICATE)
	if(LAZYLEN(nuke_candidates))
		if(QDELETED(src) || !check_usability(user))
			return
		used = TRUE
		var/mob/dead/observer/G = pick(nuke_candidates)
		spawn_antag(G.client, get_turf(src), "syndieborg", user.mind)
		do_sparks(4, TRUE, src)
		qdel(src)
	else
		to_chat(user, "<span class='warning'>Unable to connect to Syndicate command. Please wait and try again later or use the teleporter on my uplink to get my points refunded.</span>")

/obj/item/antag_spawner/nuke_ops/spawn_antag(client/C, turf/T, kind, datum/mind/user)
	var/mob/living/carbon/human/M = new/mob/living/carbon/human(T)
	C.prefs.copy_to(M)
	M.key = C.key

	var/datum/antagonist/nukeop/new_op = new()
	new_op.send_to_spawnpoint = FALSE
	new_op.nukeop_outfit = /datum/outfit/syndicate/no_crystals

	var/datum/antagonist/nukeop/creator_op = user.has_antag_datum(/datum/antagonist/nukeop,TRUE)
	if(creator_op)
		M.mind.add_antag_datum(new_op,creator_op.nuke_team)
		M.mind.special_role = "Nuclear Operative"
/*
//////CLOWN OP
/obj/item/antag_spawner/nuke_ops/clown
	name = "clown operative teleporter"
	desc = ""

/obj/item/antag_spawner/nuke_ops/clown/spawn_antag(client/C, turf/T, kind, datum/mind/user)
	var/mob/living/carbon/human/M = new/mob/living/carbon/human(T)
	C.prefs.copy_to(M)
	M.key = C.key

	var/datum/antagonist/nukeop/clownop/new_op = new /datum/antagonist/nukeop/clownop()
	new_op.send_to_spawnpoint = FALSE
	new_op.nukeop_outfit = /datum/outfit/syndicate/clownop/no_crystals

	var/datum/antagonist/nukeop/creator_op = user.has_antag_datum(/datum/antagonist/nukeop/clownop,TRUE)
	if(creator_op)
		M.mind.add_antag_datum(new_op, creator_op.nuke_team)
		M.mind.special_role = "Clown Operative"

*/
//////SYNDICATE BORG
/obj/item/antag_spawner/nuke_ops/borg_tele
	name = "syndicate cyborg teleporter"
	desc = ""
	icon = 'icons/obj/device.dmi'
	icon_state = "locator"

/obj/item/antag_spawner/nuke_ops/borg_tele/assault
	name = "syndicate assault cyborg teleporter"
	borg_to_spawn = "Assault"

/obj/item/antag_spawner/nuke_ops/borg_tele/medical
	name = "syndicate medical teleporter"
	borg_to_spawn = "Medical"

/obj/item/antag_spawner/nuke_ops/borg_tele/saboteur
	name = "syndicate saboteur teleporter"
	borg_to_spawn = "Saboteur"

/obj/item/antag_spawner/nuke_ops/borg_tele/spawn_antag(client/C, turf/T, kind, datum/mind/user)
	var/mob/living/silicon/robot/R
	var/datum/antagonist/nukeop/creator_op = user.has_antag_datum(/datum/antagonist/nukeop,TRUE)
	if(!creator_op)
		return

	switch(borg_to_spawn)
		if("Medical")
			R = new /mob/living/silicon/robot/modules/syndicate/medical(T)
		if("Saboteur")
			R = new /mob/living/silicon/robot/modules/syndicate/saboteur(T)
		else
			R = new /mob/living/silicon/robot/modules/syndicate(T) //Assault borg by default

	var/brainfirstname = pick(GLOB.first_names_male)
	if(prob(50))
		brainfirstname = pick(GLOB.first_names_female)
	var/brainopslastname = pick(GLOB.last_names)
	if(creator_op.nuke_team.syndicate_name)  //the brain inside the syndiborg has the same last name as the other ops.
		brainopslastname = creator_op.nuke_team.syndicate_name
	var/brainopsname = "[brainfirstname] [brainopslastname]"

	R.mmi.name = "[initial(R.mmi.name)]: [brainopsname]"
	R.mmi.brain.name = "[brainopsname]'s brain"
	R.mmi.brainmob.real_name = brainopsname
	R.mmi.brainmob.name = brainopsname
	R.real_name = R.name

	R.key = C.key

	var/datum/antagonist/nukeop/new_borg = new()
	new_borg.send_to_spawnpoint = FALSE
	R.mind.add_antag_datum(new_borg,creator_op.nuke_team)
	R.mind.special_role = "Syndicate Cyborg"
