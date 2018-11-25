/**
* Name: FestivalStageRating
* Author: hrabo,jcelik
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model FestivalStageRating

global {
	
	int BAND_TYPE_COUNT <- 3;
	int BAND_TYPE_POP <- 0;
	int BAND_TYPE_METAL <- 1;
	int BAND_TYPE_RAP <- 2;

	int CATEGORY_TSHIRT <- 0;
	int CATEGORY_CAP <- 1;	
	int CATEGORY_MAX <- 1;
	
	init
	{
		// Make sure we get consistent behaviour
		seed <- 10.0;
				
		create FestivalScene number: 4 {
			location <- {rnd(100), rnd(100)};
		}
		
		create FestivalGuest number: 13
		{
			location <- {rnd(100),rnd(100)};
			
			if (flip(0.5)) {
				clothing_category <- rnd_choice([0.5, 0.5]);
			}
			
			if (clothing_category = CATEGORY_CAP) {
				preference_band_types << BAND_TYPE_RAP; 
			} else if (clothing_category = CATEGORY_TSHIRT) {
				preference_band_types << BAND_TYPE_METAL;
			} else {
				preference_band_types << rnd(BAND_TYPE_COUNT) - 1;
			}

			write "["+self+"]:";
			write "\tp-band:    " + preference_rating_band;
			write "\tp-light:   " + preference_rating_lightshow;
			write "\tp-speaker: " + preference_rating_speakers;
			write "\tp-size:    " + preference_scene_size;
			write "\tp-music:   " + preference_band_types;
			write "\tp-clothing:" + clothing_category;
		}
	}
}

/* Insert your model definition here */
species FestivalScene skills: [fipa] {
	rgb myColor <- #black;
	rgb myColor_lightshow <- #green;
	point location_lightshow <- location;
	
	// Changing properties
	float property_rating_speakers <- rnd(1.0);
	float property_scene_size <- 5.0 + rnd(18.0);
	
	// Changing properties
	int   property_band_type <- rnd(BAND_TYPE_COUNT - 1);
	float property_rating_band <- rnd(1.0);
	float property_rating_lightshow <- rnd_choice([0.0, 0.2, 0.6, 0.2]) / 3.0;
	
	bool show_active <- false;
	
	int show_timeout <- 50 + rnd(500) update: show_timeout - 1 min: 0;
	
	reflex start_show when: (not show_active) and show_timeout < 1 
	{
		show_active <- true;
		show_timeout <- 300 + rnd(500);
		
		list<FestivalGuest> participants <- list<FestivalGuest> (FestivalGuest);
		
		map<string, float> property_map <- [
			'rating_band':: property_rating_band,
			'rating_lightshow':: property_rating_lightshow,
			'rating_speakers':: property_rating_speakers,
			'scene_size':: property_scene_size,
			'band_type':: property_band_type
		];
		
		write "["+self+"]: Announcing Concert";
		write "\ts-band:   " + property_rating_band;
		write "\ts-light:  " + property_rating_lightshow;
		write "\ts-speaker:" + property_rating_speakers;
		write "\ts-size:   " + property_scene_size;
		if (property_band_type = BAND_TYPE_RAP) {write "\ts-music:  RAP";}
		if (property_band_type = BAND_TYPE_METAL) {write "\ts-music:  METAL";}
		if (property_band_type = BAND_TYPE_POP) {write "\ts-music:  POP";}

		if (length(participants) > 0) {
			do start_conversation(
				to: participants, protocol: 'fipa-inform', 
				performative: 'inform', 
				contents: ['Starting Concert', property_map]
			);	
		}
	}
	
	reflex stop_show when: show_active and show_timeout < 1 
	{
		show_timeout <- 300 + rnd(500);
		show_active <- false;
		
		// Update settings
		property_band_type <- rnd(BAND_TYPE_COUNT - 1);
		property_rating_band <- rnd(1.0);
		property_rating_lightshow <- rnd_choice([0.0, 0.2, 0.6, 0.2]) / 3.0;
		
		list<FestivalGuest> participants <- list<FestivalGuest> (FestivalGuest);
		if (length(participants) > 0) {
			do start_conversation(
				to: participants, protocol: 'fipa-inform', 
				performative: 'inform', 
				contents: ['Concert Ended']
			);	
		}
	}
	
	reflex update_light_color when: show_active
	{
		if (flip(property_rating_lightshow)) {
			
			if (property_band_type = BAND_TYPE_METAL) {
				if (flip(0.5)) {
					myColor_lightshow <- #white;
				} else {
					myColor_lightshow <- #gray;
				}
			} else if (property_band_type = BAND_TYPE_RAP) {
				if (flip(0.5)) {
					myColor_lightshow <- #red;
				} else {
					myColor_lightshow <- #white;
				}
			} else {
				myColor_lightshow <- rnd_color(255);	
			}
			
			location_lightshow <- {location.x + rnd(property_scene_size) - property_scene_size / 2, location.y + rnd(property_scene_size) - property_scene_size / 2};
		}
	}
	
	aspect default{
		if (show_active) {
			draw 	circle(property_scene_size*1.5) 
					at: location_lightshow 
					color: myColor_lightshow;	
		}
		
    	draw cube(property_scene_size) at: {location.x, location.y, property_scene_size - 3} color: myColor;
    }
}

species FestivalGuest skills: [moving, fipa] {
	rgb myColor <- #red;
	FestivalScene festival_scene;
	float current_scene_rating <- 0.0;
	point target_point;
	
	float preference_rating_band <- rnd(1.0);
	float preference_rating_lightshow <- rnd(0.2, 1.0);
	float preference_rating_speakers <- rnd(1.0);
	float preference_scene_size <- rnd(1.0);
	list<int>   preference_band_types <- [];

	// Clothing
	int clothing_category <- -1;
	
	reflex go_to_concert 
		when:  	festival_scene != nil 
		and 	target_point = nil
		and 	location distance_to festival_scene > festival_scene.property_scene_size*1.5
	{
		do goto target:festival_scene;
	}
	
	reflex dance 
		when:  	festival_scene != nil 
		and 	target_point = nil
		and 	location distance_to festival_scene <= festival_scene.property_scene_size*1.5
	{
		do wander;
	}
	
	reflex go_to_target_point when: target_point != nil
	{
		do goto target:target_point;
		
		if location distance_to target_point < 2
		{
			target_point <- nil;
		}
	}
	
	// Selects an auction when a new auctioneer comes.
	reflex check_inform_messages when: !empty(informs)
	{
		loop info over: informs
		{
			if (info.contents at 0 = "Starting Concert")
			{
				map<string, float> properties <- map<string,float> (info.contents at 1);
				float personal_scene_rating <-
					preference_rating_band 		* properties["rating_band"] +
					preference_rating_lightshow * properties["rating_lightshow"] + 
					preference_rating_speakers 	* properties["rating_speakers"] +
					preference_scene_size 		* properties["scene_size"] / 20;
					
				if (properties["band_type"] in preference_band_types) {
					personal_scene_rating <- personal_scene_rating + 2; 
				}
				
				
				if (current_scene_rating < personal_scene_rating) {
					current_scene_rating <- personal_scene_rating;
					festival_scene <- info.sender;
				
					write "["+self+"] - Leavng for new concert w p-rating ("+info.sender+"): " + personal_scene_rating;
				} else {
					write "["+self+"] - Ignoring new concert w p-rating ("+info.sender+"): " + personal_scene_rating;
				}
			
				
			} else if (info.contents at 0 = "Concert Ended" and festival_scene != nil) {
				if (info.sender = festival_scene) {
					target_point <- {rnd(100), rnd(100)};
					festival_scene <- nil;
					current_scene_rating <- 0.0;
					write "["+self+"] - Leavng concert that ended";	
				}
			}
		}
		
		informs <- [];
	}
	
	aspect default {
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
    	
    	switch clothing_category
		{
			match CATEGORY_TSHIRT
			{
				draw pyramid(2.5) at: {location.x, location.y, 1.1} color: #black;
			}
			match CATEGORY_CAP
			{
				draw cylinder(1.3, 0.1) at: {location.x + 1.2, location.y, 4.5} color: #white;
				draw cylinder(1.5, 1.5) at: {location.x, location.y, 4.5} color: #white;
			}
		}
    }
}

/*Running the experiment*/
experiment main type: gui {
	output {
		display map type: opengl 
		{
		
			image file: "grass.jpg";
			species FestivalGuest;
			species FestivalScene;
		}
	}
}


