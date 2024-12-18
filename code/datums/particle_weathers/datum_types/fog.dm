//Fog
/particles/weather/fog
	icon 				   = 'icons/effects/96x96.dmi'
	icon_state             = list("smoke-static" = 5)
	gradient               = list(0,"#a1a1a1e3",10,"#e2dcd8e3","loop")
	color                  = 0
	color_change		   = generator("num",0,3)
	position               = generator("box", list(-500,-256,0), list(500,500,0))
	gravity                = list(-5 -1, 0.1)
	drift                  = generator("circle", 0, 3) // Some random movement for variation
	friction               = 0.3  // shed 30% of velocity and drift every 0.1s
	//Weather effects, max values
	maxSpawning           = 120
	maxSpawning           = 40
	wind                   = 10

/datum/particle_weather/fog
	name = "Fog"
	desc = "Gentle fog, la la description."
	particleEffectType = /particles/weather/fog

	scale_vol_with_severity = TRUE
	weather_sounds = list(/datum/looping_sound/rain)
	indoor_weather_sounds = list(/datum/looping_sound/indoor_rain)
	weather_messages = list("The rain cools your skin.")

	minSeverity = 5
	maxSeverity = 15
	maxSeverityChange = 2
	severitySteps = 5
	immunity_type = TRAIT_RAINSTORM_IMMUNE
	probability = 1
	target_trait = PARTICLEWEATHER_RAIN
	#ifndef  SPACEMAN_DMM
	filter_type = filter(type="alpha", render_source = O_LIGHTING_VISUAL_RENDER_TARGET, flags = MASK_INVERSE)
	#endif

	var/old_plane

/datum/particle_weather/fog/start()
	. = ..()
	for(var/area/area in world)
		if(area.outdoors)
			if(!old_plane)
				old_plane = area.plane
			area.icon 			  = 'icons/effects/weather_overlay.dmi'
			area.icon_state 		  = "weather_overlay"
			area.plane			  = WEATHER_OVERLAY_PLANE
			area.blend_mode   	  = BLEND_OVERLAY
			area.invisibility 	  = INVISIBILITY_LIGHTING

/datum/particle_weather/fog/end()
	. = ..()
	for(var/area/area in world)
		if(area.outdoors)
			area.icon = initial(area.icon)
			area.icon_state = ""
			area.plane			  = old_plane
			area.blend_mode   	  = initial(area.blend_mode)
			area.invisibility 	  = initial(area.invisibility)
	old_plane = null