/**
* Name: FestivalSimulation
* Author: hrabo, jcelik
* Description: 
*/

model FestivalSimulation

global {
	
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
	
	int MUSIC_CATEGORY_ROCK 	<- 0;
	int MUSIC_CATEGORY_POP 		<- 1;
	int MUSIC_CATEGORY_RAP 		<- 2;
	int MUSIC_CATEGORY_JAZZ 	<- 3;
	
	list<int> MUSIC_CATEGORIES <- [
		MUSIC_CATEGORY_ROCK,
		MUSIC_CATEGORY_POP,
		MUSIC_CATEGORY_RAP,
		MUSIC_CATEGORY_JAZZ
		];
	
	map default_state <- [
		"in_bar":: false,
		"likes_music":: false,
		"crowded":: false,
		"criminal_danger":: false,
		"thirsty":: false,
		"generous_close":: false,
		"party_lover_close":: false,
		"drunkness":: 0
	];
			
	
	// Important that Concert and Bar gets updated before agent as they are used to count agent on location.
	init
	{
		// TODO: Place on good locations
		create FestivalConcert 		number: 2 {}
		create FestivalBar 			number: 3 {}
		create MovingFestivalAgent 	number: 50 {}
	}
	
	// Make the world bigger
	geometry shape <- envelope(square(200));
	
	int minute <- 3;
	int hour <- minute * 60;
	int day <- hour * 24;
	int simulation_time <- day * 3;
	
	reflex t when : cycle >= simulation_time {
		 do pause;
	}
}

species FestivalBar skills: [] {
	rgb myColor <- #green;
	
	// Calculates if crowded, medium, empty
	// Calculates most common agent of normal or party lover
	// Does there exist a criminal?
	// Does there exist a security guard?
	
	int agentsInLocation <- 0 update: length(MovingFestivalAgent at_distance(5));
	
	aspect default{
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}

species FestivalConcert skills: [fipa] {
	rgb myColor <- #black;
	
	int agentsInLocation <- 0 update: length(MovingFestivalAgent at_distance(5));
	
	aspect default{
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}


// At least 5 moving agents
species MovingFestivalAgent skills: [moving, fipa] {
	// TODO: rnd_choise has normal distribution. I think we want even distribution. I might be wrong. I am confused.
	int agent_type 					<- AGENT_TYPES at rnd_choice(AGENT_DISTRIBUTION);
	rgb myColor 					<- AGENT_COLORS at agent_type;
	
	bool transporting_agent	 		<- false;
		
	//  Q is a two-dimensions matrix with 5 columns and 5 rows, where each cell is initialized to 0.
	// Columns represent state and row represents actions.
	matrix Q <- 0 as_matrix({10,5});
	map oldState;
	
	point target_location <- nil;
	
	float agent_current_happiness 	<- AGENT_HAPPINESS_NEUTRAL;
	float agent_avg_happiness 		<- AGENT_HAPPINESS_NEUTRAL 
			update: AGENT_HAPPINESS_UPDATE_ALPHA * agent_current_happiness + agent_avg_happiness * (1 - AGENT_HAPPINESS_UPDATE_ALPHA);
	
	// Traits
	float 	agent_trait_thirst 		<- rnd(10.0);
	float	agent_trait_generosity 	<- rnd(10.0);
	int 	agent_trait_fav_music	<- first(1 among MUSIC_CATEGORIES);
	float 	drunkness 				<- rnd(10.0);
	
	reflex move_to_target when: target_location != nil
	{
		if location distance_to target_location < 3
		{
			transporting_agent <- false;
			target_location <- nil;
		} 
		else 
		{
			do goto target:target_location;
		}
	}
	
	float interact_with_location {
		return AGENT_HAPPINESS_NEUTRAL;
	}
		
	// Return the happiness from this agent
	float R(map state, int agent_action) {
		switch agent_type {
			match(AGENT_TYPE_NORMAL) {
				return R_normal(state, agent_action);
			} match(AGENT_TYPE_PARTY_LOVER) {
				return R_normal(state, agent_action);
			} match (AGENT_TYPE_CRIMINAL) {
				return R_criminal(state, agent_action);
			} match (AGENT_TYPE_JOURNALIST) {
				return R_journalist(state, agent_action);
			} match (AGENT_TYPE_SECURITY_GUARD) {
				return R_security(state, agent_action);
			}
		}
	}
	
	float R_normal(map state, int agent_action) {
		write state["hello"];
		return 0.0;
	}
	
	float R_party_lover(map state, int agent_action) {
		return 0.0;
	}
	
	float R_criminal(map state, int agent_action) {
		return 0.0;
	}
	
	float R_journalist(map state, int agent_action) {
		return 0.0;
	}
	
	float R_security(map state, int agent_action) {
		return 0.0;
	}
		
	reflex update_happiness when: !transporting_agent {
		
		// 1.
		
		// 1. Calculate new state
		
		// 2. 
		
//		float accumulated_happiness <- 0.0;
//		
//		list<MovingFestivalAgent> closeby_agents <- MovingFestivalAgent at_distance 5 where (each.agent_state = AGENT_STATE_ACTIVE);
//		
//		loop other_agent over: closeby_agents {
//			accumulated_happiness <- accumulated_happiness + interact_with_agent(other_agent);
//		}
//		
//		accumulated_happiness <- accumulated_happiness + interact_with_location();
//		
//		agent_current_happiness <- accumulated_happiness / (length(closeby_agents) + 1);
	}
	
	aspect default {
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
	}
}


experiment main type: gui {
	output {
		display map type: opengl 
		{
			species FestivalConcert;
			species FestivalBar;
			species MovingFestivalAgent;
		}
		
		display chart refresh:every(10.0)
		{
			chart "Happiness" type: series size: {1, 0.5} position: {0, 0}
			{	
				data "Avg. Happiness" value: (MovingFestivalAgent sum_of(each.agent_current_happiness));
			}
			
			chart "Agent Distribution" type: pie size: {1, 0.5} position: {0, 0.5}
			{
				data "Normal" 		value: length(MovingFestivalAgent where (each.agent_type = AGENT_TYPE_NORMAL)) color: AGENT_COLORS at AGENT_TYPE_NORMAL;
				data "Party Lover" 	value: length(MovingFestivalAgent where (each.agent_type = AGENT_TYPE_PARTY_LOVER)) color: AGENT_COLORS at AGENT_TYPE_PARTY_LOVER;
				data "Criminal" 	value: length(MovingFestivalAgent where (each.agent_type = AGENT_TYPE_CRIMINAL)) color: AGENT_COLORS at AGENT_TYPE_CRIMINAL;
				data "Journalist" 	value: length(MovingFestivalAgent where (each.agent_type = AGENT_TYPE_JOURNALIST)) color: AGENT_COLORS at AGENT_TYPE_JOURNALIST;
				data "Security" 	value: length(MovingFestivalAgent where (each.agent_type = AGENT_TYPE_SECURITY_GUARD)) color: AGENT_COLORS at AGENT_TYPE_SECURITY_GUARD;
			
			}
		}
		
	}
}

