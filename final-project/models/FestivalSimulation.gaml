/**
* Name: FestivalSimulation
* Author: hrabo, jcelik
* Description: 
*/

model FestivalSimulation

global {
	
	float ALPHA <- 0.2;
	float GAMMA <- 0.5;
	
	float WALK_RANDOMNESS_TRAINING <- 0.9;
	float WALK_RANDOMNESS_SIMULATION <- 0.2;
	
	float walk_randomness <- WALK_RANDOMNESS_TRAINING;
	
	int AGENT_TYPE_NORMAL 			<- 0;
	int AGENT_TYPE_PARTY_LOVER 		<- 3;
	int AGENT_TYPE_CRIMINAL 		<- 1;
	int AGENT_TYPE_JOURNALIST		<- 2;
	int AGENT_TYPE_SECURITY_GUARD 	<- 4;
	
	list<int> AGENT_TYPES <- [
		AGENT_TYPE_NORMAL, 				// Gets slightly more happy by normal people around them. Will get less happy by party lovers. Likes bars more than scenes.
		AGENT_TYPE_PARTY_LOVER,			// Get very much more happy by more people. Especially pary lovers. Prefers scenes but will get happy if bar is full.
		AGENT_TYPE_CRIMINAL,			// 
		AGENT_TYPE_JOURNALIST,			// 
		AGENT_TYPE_SECURITY_GUARD		// 
	 	];
	 	
	 list<float> AGENT_DISTRIBUTION <- [
	 	0.45,
	 	0.35,
	 	0.1,
	 	0.05,
	 	0.05
	 	];
	 	
	 list<rgb> AGENT_COLORS <- [
	 	#red,
	 	#black,
	 	#white,
	 	#purple,
	 	#blue
	 	];
	 	
	float AGENT_HAPPINESS_NEUTRAL		<- 0.5; 
	float AGENT_HAPPINESS_UPDATE_ALPHA 	<- 0.8;
	
	int MUSIC_CATEGORY_NONE		<- 0;
	int MUSIC_CATEGORY_ROCK 	<- 1;
	int MUSIC_CATEGORY_POP 		<- 2;
	int MUSIC_CATEGORY_RAP 		<- 3;
	int MUSIC_CATEGORY_JAZZ 	<- 4;
	
	list<int> MUSIC_CATEGORIES <- [
		MUSIC_CATEGORY_ROCK,
		MUSIC_CATEGORY_POP,
		MUSIC_CATEGORY_RAP,
		MUSIC_CATEGORY_JAZZ
		];
		
	int STATE_DRUNKNESS_NONE 	<- 0;
	int STATE_DRUNKNESS_BUZZED 	<- 1;
	int STATE_DRUNKNESS_WASTED 	<- 2;
	
	int ACTION_GOTO_CONCERT_0 	<- 0;
	int ACTION_GOTO_CONCERT_1 	<- 1;
	int ACTION_GOTO_BAR_0 		<- 2;
	int ACTION_GOTO_BAR_1 		<- 3;
	int ACTION_GOTO_BAR_2 		<- 4;
	int ACTION_DRINK_WATER 		<- 5;
	int ACTION_DRINK_BEER 		<- 6;
	int ACTION_DANCE 			<- 7;
	
	list<int> ACTIONS <- [
		ACTION_GOTO_CONCERT_0,
		ACTION_GOTO_CONCERT_1,
		ACTION_GOTO_BAR_0,
		ACTION_GOTO_BAR_1,
		ACTION_GOTO_BAR_2,
		ACTION_DRINK_WATER,
		ACTION_DRINK_BEER,
		ACTION_DANCE
	];
	
	map<string, int> default_state <- [
		"in_bar"			:: 0,
		"likes_music"		:: 0,
		"crowded"			:: 0,
		"criminal_danger"	:: 0,
		"thirsty"			:: 0,
		"party_lover_close"	:: 0,
		"drunkness"			:: 0
	];
	
	list<point> bar_locations <- [
		{30, 30},
		{30, 180},
		{180, 30}
	];
	
	list<point> concert_locations <- [
		{100, 60},
		{160, 160}
	];	
	
	FestivalBar bar0;
	FestivalBar bar1;
	FestivalBar bar2;
	
	FestivalConcert con0;
	FestivalConcert con1;
	
	// Important that Concert and Bar gets updated before agent as they are used to count agent on location.
	init
	{
		int agent_index <- 0;
		
		create FestivalConcert number: length(concert_locations) {
			location <- concert_locations[agent_index];
			agent_index <- agent_index + 1;
		}
		
		agent_index <- 0;
		
		create FestivalBar number: length(bar_locations) {
			location <- bar_locations[agent_index];
			agent_index <- agent_index + 1;
		}
		
		create MovingFestivalAgent 	number: 50 {
			if (flip(0.4)) {
				target_location <- FestivalConcert[rnd(length(concert_locations) - 1)].location;				
			} else {
				target_location <- FestivalBar[rnd(length(bar_locations) - 1)].location;
			}
		}
	}
	
	// Make the world bigger
	geometry shape <- envelope(square(200));
	
	int minute <- 3;
	int hour <- minute * 60;
	int day <- hour * 24;
	int simulation_time <- day * 3;
	
	int training_step_0 <- 10000;
	int training_step_1 <- 10000;
	int training_step_2 <- 10000;
	int training_time <- training_step_0 + training_step_1 + training_step_2;
	
	reflex learning when: time = 0 or time = training_step_0 + training_step_1 {
		walk_randomness <- WALK_RANDOMNESS_TRAINING;
		write "LEARNING MODE";
	}
	
	reflex simulating when: time = training_step_0 or time = training_step_0 + training_step_1 + training_step_2 {
		walk_randomness <- WALK_RANDOMNESS_SIMULATION;
		write "SIMULATION MODE";
	}
	
	reflex t when : cycle >= (training_time + simulation_time) or cycle = training_time {
		 do pause;
	}
}

species FestivalBar skills: [] {
	rgb myColor <- #pink;
		
	list<MovingFestivalAgent> closeby_agents <- [] update: MovingFestivalAgent at_distance(10);
	bool crowded 		<- false update: length(closeby_agents) > 5;
	bool has_security 	<- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) > 1;
	bool has_criminal 	<- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) > 1;
	bool has_partylover <- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) > 1;
	
	int music			<- first(1 among MUSIC_CATEGORIES + MUSIC_CATEGORY_NONE);
	
	aspect default {
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}

species FestivalConcert skills: [] {
	float scene_size <- 10.0;
	rgb myColor <- #black;
	rgb myColor_lightshow <- #green;
	point location_lightshow <- location;
	
	list<MovingFestivalAgent> closeby_agents <- [] update: MovingFestivalAgent at_distance(5);
	bool crowded 		<- false update: length(closeby_agents) > 5;
	bool has_security 	<- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) > 1;
	bool has_criminal 	<- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) > 1;
	bool has_partylover <- false update: length(closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) > 1;
	
	int music			<- first(1 among MUSIC_CATEGORIES);
	
	reflex update_light_color
	{
		if (flip(0.2) or time = 0) {
			switch music {
				match MUSIC_CATEGORY_ROCK {
					if (flip(0.5)) {
						myColor_lightshow <- #white;
					} else {
						myColor_lightshow <- #gray;
					}
				}
				match MUSIC_CATEGORY_POP {
					if (flip(0.5)) {
						myColor_lightshow <- #pink;
					} else {
						myColor_lightshow <- #purple;
					}
				}
				match MUSIC_CATEGORY_RAP {
					if (flip(0.5)) {
						myColor_lightshow <- #white;
					} else {
						myColor_lightshow <- #red;
					}
				}
				match MUSIC_CATEGORY_JAZZ {
					if (flip(0.5)) {
						myColor_lightshow <- #yellow;
					} else {
						myColor_lightshow <- #brown;
					}
				}
			}
			
			location_lightshow <- {location.x + rnd(scene_size) - scene_size / 2, location.y + rnd(scene_size) - scene_size / 2};
		}
	}
	
	aspect default {		
		draw circle(scene_size*1.5) at: location_lightshow color: myColor_lightshow;
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}


// At least 5 types of  moving agents
species MovingFestivalAgent skills: [moving] {
	int agent_type 					<- AGENT_TYPES at rnd_choice(AGENT_DISTRIBUTION);
	rgb myColor 					<- AGENT_COLORS at agent_type;
	
	// Traits
	float 	agent_trait_thirst 		<- rnd(10.0) min: 0.0 max: 10.0 update: agent_trait_thirst + 0.005;
	float 	agent_trait_drunkness 	<- rnd(10.0) min: 0.0 max: 10.0 update: agent_trait_drunkness - 0.005; 
	int 	agent_trait_fav_music	<- first(1 among MUSIC_CATEGORIES);
	
	float agent_happiness <- -10.0 min: 0.0 max: 10.0;

	// Q is a two-dimensions matrix with 8 columns and 192 rows, where each cell is initialized to 0.
	// Columns represent actions and row represents state.
	matrix Q <- 0.0 as_matrix({8, 192});
	map<string, int> old_state <- copy(default_state);
	int old_action;
	
	point target_location <- nil;
	
	reflex move_to_target when: target_location != nil
	{
		if location distance_to target_location < 3
		{
			target_location <- nil;
		} 
		else
		{
			do goto target:target_location speed: 10.0;
		}
	}

	int get_s_index(map<string,int> state) {
		return (
			state["in_bar"] 			* 2^0 +
			state["likes_music"] 		* 2^1 +
			state["crowded"] 			* 2^2 +
			state["criminal_danger"]	* 2^3 +
			state["thirsty"] 			* 2^4 +
			state["party_lover_close"] 	* 2^5 +
			state["drunkness"] 			* 2^6 // Drunkness is any value in [0,3] which means that further expansions must be alligned to that
		);
	}
	
	map<string, int> get_state {
		map new_state <- copy(default_state);
		
		FestivalBar 	bar_closeby 	<- first(FestivalBar at_distance(5));
		FestivalConcert concert_closeby <- first(FestivalConcert at_distance(5));
		
		bool likes_music;
		bool crowded;
		bool criminal_danger;
		bool party_lover_close;
		if (bar_closeby != nil) {
			likes_music 		<- bar_closeby.music = agent_trait_fav_music;
			crowded 			<- bar_closeby.crowded;
			party_lover_close 	<- bar_closeby.has_partylover;
			
			if (agent_type = AGENT_TYPE_CRIMINAL) {
				criminal_danger	<- bar_closeby.has_security;
			} else {
				criminal_danger	<- bar_closeby.has_criminal and not bar_closeby.has_security;
			}
		} else {
			likes_music 		<- concert_closeby.music = agent_trait_fav_music;
			crowded 			<- concert_closeby.crowded;
			party_lover_close 	<- concert_closeby.has_partylover;
			
			if (agent_type = AGENT_TYPE_CRIMINAL) {
				criminal_danger	<- concert_closeby.has_security;
			} else {
				criminal_danger	<- concert_closeby.has_criminal and not concert_closeby.has_security;
			}
		}
		
		int drunkness <- STATE_DRUNKNESS_NONE;
		if (agent_trait_drunkness > 4) {
			drunkness <- STATE_DRUNKNESS_BUZZED;
		} 
		
		if (agent_trait_drunkness > 8) {
			drunkness <- STATE_DRUNKNESS_WASTED;
		}
		
		new_state["in_bar"]             <- (bar_closeby != nil) 	as int;
		new_state["likes_music"]        <- likes_music 				as int;
		new_state["crowded"]            <- crowded 					as int;
		new_state["criminal_danger"]    <- criminal_danger 			as int;
		new_state["thirsty"]            <- (agent_trait_thirst > 5) as int;
		new_state["party_lover_close"]  <- party_lover_close 		as int;
		new_state["drunkness"]          <- drunkness;
		
		return new_state; 
	}
	
	float normalize_R(float value) {
		if (value > 10.0) { return 10;}
		if (value < -10.0) { return -10;}
		return value;
	}
	
	// Return the happiness from this agent
	float R(map<string, int> state, int agent_action) {
		float r_raw;
		switch agent_type {
			match(AGENT_TYPE_NORMAL) {
				r_raw <- R_normal(state, agent_action);
			} match(AGENT_TYPE_PARTY_LOVER) {
				r_raw <- R_normal(state, agent_action);
			} match (AGENT_TYPE_CRIMINAL) {
				r_raw <- R_criminal(state, agent_action);
			} match (AGENT_TYPE_JOURNALIST) {
				r_raw <- R_journalist(state, agent_action);
			} match (AGENT_TYPE_SECURITY_GUARD) {
				r_raw <- R_security(state, agent_action);
			}
		}
		
		return normalize_R(r_raw);
	}
	
	float R_normal(map<string, int> state, int agent_action) {
		float happiness <- 0.0;
		
		if (state["thirsty"] = 1) {
			happiness <- happiness - 3;
			
		}
		
		if (state["in_bar"] = 1) {
			happiness <- happiness + 4.0;
			if(state["drunkness"] = STATE_DRUNKNESS_BUZZED) {
				happiness <- happiness + 4.0;
			}
		} else if (state["likes_music"] = 1) {
			if(state["drunkness"] = STATE_DRUNKNESS_BUZZED) {
				happiness <- happiness + 6.0;
			} else {
				happiness <- happiness + 1.0;
			}
		}
		
		if (state["crowded"] = 0) {
			happiness <- happiness + 1.0;
		}
		
		if (state["drunkness"] = STATE_DRUNKNESS_WASTED) {
			happiness <- happiness - 10.0;
		}
		
		if (state["criminal_danger"] = 1) {
			happiness <- happiness - 4.0;
		}
		
		if ((state["party_lovers_close"] = 1) and (state["drunkness"] = STATE_DRUNKNESS_NONE)) {
			happiness <- happiness - 4.0;
		}
		
		return happiness;
	}
	
	float R_party_lover(map<string, int> state, int agent_action) {
		float happiness <- 0.0;
		
		if (state["thirsty"] = 1) {
			happiness <- happiness - 3;
		}
		
		if (state["in_bar"] = 0) {
			happiness <- happiness + 1.0;
		}
		
		if (state["crowded"] = 1) {
			happiness <- happiness + 4.0;
		}
		
		if (state["party_lover_close"] = 1) {
			happiness <- happiness + 1;
		}
		
		switch state["drunkness"] {
			match STATE_DRUNKNESS_NONE {
				if (state["likes_music"] = 0) {
					happiness <- happiness + 1.0;
				}  else {
					happiness <- happiness + 2.0;
				}
			}
			match STATE_DRUNKNESS_BUZZED {
				if (state["likes_music"] = 0) {
					happiness <- happiness + 5.0;
				}  else {
					happiness <- happiness + 10.0;
				}
			}
			match STATE_DRUNKNESS_WASTED {
				happiness <- happiness - 3.0;
			}
		}
		
		if (state["criminal_danger"] = 1) {
			happiness <- happiness + 1;
		}
		
		return happiness;
	}
	
	float R_criminal(map<string, int> state, int agent_action) {
		float happiness <- 0.0;
		
		if (state["thirsty"] = 1) {
			happiness <- happiness - 2.0;
		}
		
		if (state["likes_music"] = 1) {
			happiness <- happiness + 3 + (state["drunkness"] * 1.5);
		}
		
		if (state["drunkness"] = STATE_DRUNKNESS_BUZZED) {
			happiness <- happiness + 3.0;
		}
		
		if (state["crowded"] = 0) {
			happiness <- happiness - 3.0;
		}
		
		// The presense of a security guard 
		if (state["criminal_danger"] = 1) {
			happiness <- happiness - 7.0 - (state["drunkness"] * 10);
		}
		
		if (state["party_lovers_close"] = 1) {
			happiness <- happiness + 4.0;
		}
		
		return happiness;
	}
	
	float R_journalist(map<string, int> state, int agent_action) {
		float happiness <- 0.0;
		
		if (state["thirsty"] = 1) {
			happiness <- happiness - 2;
		}
		
		if (state["drunkness"] > STATE_DRUNKNESS_NONE) {
			happiness <- happiness - (state["drunkness"] * 2.0);
		}
		
		if (state["crowded"] = 1) {
			happiness <- happiness + 2;
		}
		
		if (state["in_bar"] = 0) {
			if(state["likes_music"] = 1) {
				happiness <- happiness + 2;				
			} else {
				happiness <- happiness + 3;
			}
		}
		
		if (state["criminal_danger"] = 1) {
			happiness <- happiness + 5;
		}
			
		return happiness;
	}
	
	float R_security(map<string, int> state, int agent_action) {
		float happiness <- 0.0;
		
		if (state["thirsty"] = 1) {
			happiness <- happiness - 2;
		}
		
		
		if (state["crowded"] = 1) {
			happiness <- happiness + 2;
		}
		
		if (state["drunkness"] > STATE_DRUNKNESS_NONE) {
			happiness <- happiness - 12;
		}
		
		if (state["criminal_danger"] = 1) {
			happiness <- happiness + 10;
		}
		
		return happiness;
	}
	
	float max_Q(map<string, int> state) {
		int row_index <- get_s_index(state);
		list<float> row <- Q row_at row_index;
		
		return max(row);
	}
	
	int choose_action(map<string, int> state) {
		// Take action from state.
		if (flip(walk_randomness)) {
			return first(1 among ACTIONS);
		} else {
			int row_index <- get_s_index(state);
			list<float> row <- Q row_at row_index;
			
			int i <- 0;
			float max <- row[0];
			int best_index <- 0;
			loop element over: row {
				if (element > max) {
					max <- element;
					best_index <- i;
				}
				
				i <- i + 1;
			}
			
			return best_index;
		}
	}
	
	action execute_action (int agent_action, bool in_bar) {
		switch agent_action {
			match(ACTION_GOTO_CONCERT_0) {
				target_location <- FestivalConcert[0].location;
			}
			match(ACTION_GOTO_CONCERT_1) {
				target_location <- FestivalConcert[1].location;
			}
			match(ACTION_GOTO_BAR_0) {
				target_location <- FestivalBar[0].location;
			}
			match(ACTION_GOTO_BAR_1) {
				target_location <- FestivalBar[1].location;
			}
			match(ACTION_GOTO_BAR_2) {
				target_location <- FestivalBar[2].location;
			}
			match(ACTION_DRINK_WATER) {
				if (in_bar) {
					agent_trait_thirst <- agent_trait_thirst - 3.0;
					agent_trait_drunkness <- agent_trait_drunkness - 1;
				} else {
					agent_trait_thirst <- agent_trait_thirst - 0.25;
				}
			}
			match(ACTION_DRINK_BEER) {
				if (in_bar) {
					agent_trait_thirst <- agent_trait_thirst - 1.5;
					agent_trait_drunkness <- agent_trait_drunkness + 2.5;	
				} else {
					agent_trait_thirst <- agent_trait_thirst - 0.05;
					agent_trait_drunkness <- agent_trait_drunkness + 0.25;
				}
			}
			match(ACTION_DANCE) {
				
			}
		}
	}
	
	reflex update_happiness when: target_location = nil {
		map<string, int> state <- get_state();
		
		int old_s_index <- get_s_index(old_state);
		float old_Q <- Q[old_action, old_s_index];
		agent_happiness <- R(old_state, old_action);
		float new_Q <- old_Q + ALPHA * (agent_happiness + (GAMMA * max_Q(state)) - old_Q);
		
		Q[old_action, old_s_index] <- new_Q; 

		int agent_action <- choose_action(state);
		do execute_action(agent_action, state["in_bar"] = 1);

		old_state <- state;
		old_action <- agent_action;
	}
	
	aspect default {
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
	}
}


experiment main type: gui {
	
//	parameter "Randomness in walk: " var: walk_randomness min: 0.0 max: 1.0;
	
	output {
		display chart refresh:every(50.0)
		{
			chart "Happiness" type: series size: {1, 1} position: {0, 0}
			{	
				data "Avg. Happiness" value: (MovingFestivalAgent sum_of(each.agent_happiness) / length(MovingFestivalAgent));
				data "Nr. wasted" value: length(MovingFestivalAgent where (each.old_state["drunkness"] = STATE_DRUNKNESS_WASTED))/2;
				data "Nr. buzzed" value: length(MovingFestivalAgent where (each.old_state["drunkness"] = STATE_DRUNKNESS_BUZZED))/2;
			}
		}
		
		display concerts refresh:every(10.0) {
			chart "Concert 0 Distribution" type: series size: {1, 0.5} position: {0, 0}
			{
				con0 <- FestivalConcert at 0;
				data "Normal" 		value: length(con0.closeby_agents where (each.agent_type = AGENT_TYPE_NORMAL)) 			color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(con0.closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) 	color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(con0.closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) 		color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(con0.closeby_agents where (each.agent_type = AGENT_TYPE_JOURNALIST)) 		color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(con0.closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) 	color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			}
			chart "Concert 1 Distribution" type: series size: {1, 0.5} position: {0, 0.5}
			{
				con1 <- FestivalConcert at 1;
				data "Normal" 		value: length(con1.closeby_agents where (each.agent_type = AGENT_TYPE_NORMAL)) 			color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(con1.closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) 	color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(con1.closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) 		color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(con1.closeby_agents where (each.agent_type = AGENT_TYPE_JOURNALIST)) 		color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(con1.closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) 	color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			}
		}
		
		display bars refresh:every(10.0)
		{	
			chart "Bar 0 Distribution" type: series size: {1, 0.33} position: {0, 0}
			{
				bar0 <- FestivalBar at 0;
				data "Normal" 		value: length(bar0.closeby_agents where (each.agent_type = AGENT_TYPE_NORMAL)) 			color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(bar0.closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) 	color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(bar0.closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) 		color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(bar0.closeby_agents where (each.agent_type = AGENT_TYPE_JOURNALIST)) 		color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(bar0.closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) 	color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			}
			chart "Bar 1 Distribution" type: series size: {1, 0.33} position: {0, 0.33}
			{
				bar1 <- FestivalBar at 1;
				data "Normal" 		value: length(bar1.closeby_agents where (each.agent_type = AGENT_TYPE_NORMAL)) 			color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(bar1.closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) 	color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(bar1.closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) 		color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(bar1.closeby_agents where (each.agent_type = AGENT_TYPE_JOURNALIST)) 		color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(bar1.closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) 	color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			}
			chart "Bar 2 Distribution" type: series size: {1, 0.33} position: {0, 0.66}
			{
				bar2 <- FestivalBar at 2;
				data "Normal" 		value: length(bar2.closeby_agents where (each.agent_type = AGENT_TYPE_NORMAL)) 			color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(bar2.closeby_agents where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) 	color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(bar2.closeby_agents where (each.agent_type = AGENT_TYPE_CRIMINAL)) 		color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(bar2.closeby_agents where (each.agent_type = AGENT_TYPE_JOURNALIST)) 		color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(bar2.closeby_agents where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) 	color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			}
		}
		
		
		display map type: opengl 
		{
			image file: "grass.jpg";
			
			species FestivalConcert;
			species FestivalBar;
			species MovingFestivalAgent;
			
		}
	}
}

