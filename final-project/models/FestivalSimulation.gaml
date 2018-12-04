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
		AGENT_TYPE_NORMAL, 
		AGENT_TYPE_PARTY_LOVER,
		AGENT_TYPE_CRIMINAL,
		AGENT_TYPE_JOURNALIST,
		AGENT_TYPE_SECURITY_GUARD
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
	
	int AGENT_STATE_IDLE 		<- 0;
	int AGENT_STATE_TRANSPORT 	<- 1;
	int AGENT_STATE_ACTIVE 		<- 2;
	
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
	
	init
	{
		create FestivalConcert 		number: 2 {}
		create FestivalBar 			number: 3 {}
		create MovingFestivalAgent 	number: 50 {}
	}
	
	geometry shape <- envelope(square(200));
}

species FestivalBar skills: [] {
	rgb myColor <- #green;
	
	aspect default{
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}

species FestivalConcert skills: [fipa] {
	rgb myColor <- #black;
	
	aspect default{
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}


// At least 5 moving agents
species MovingFestivalAgent skills: [moving, fipa] {
	int agent_type 					<- AGENT_TYPES at rnd_choice(AGENT_DISTRIBUTION);
	rgb myColor 					<- AGENT_COLORS at agent_type;
	int agent_state 				<- AGENT_STATE_IDLE;
	
	point target_location <- nil;
	
	float agent_current_happiness 	<- AGENT_HAPPINESS_NEUTRAL;
	float agent_avg_happiness 		<- AGENT_HAPPINESS_NEUTRAL 
			update: AGENT_HAPPINESS_UPDATE_ALPHA * agent_current_happiness + agent_avg_happiness * (1 - AGENT_HAPPINESS_UPDATE_ALPHA);
	
	// Traits
	float 	agent_trait_thirst 		<- rnd(1.0);
	float	agent_trait_generosity 	<- rnd(1.0);
	int 	agent_trait_fav_music	<- first(1 among MUSIC_CATEGORIES);
	
	
	reflex move_to_target when: target_location != nil
	{	
		if location distance_to target_location < 3
		{
			agent_state <- AGENT_STATE_ACTIVE;
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
	float interact_with_agent(MovingFestivalAgent other_agent) {
		switch agent_type {
			match(AGENT_TYPE_NORMAL) {
				return agent_interaction_normal(other_agent);
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return agent_interaction_party_lover(other_agent);
			}
			match(AGENT_TYPE_CRIMINAL) {
				return agent_interaction_criminal(other_agent);
			}
			match(AGENT_TYPE_JOURNALIST) {
				return agent_interaction_journalist(other_agent);
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return agent_interaction_security_guard(other_agent);
			}
			default {
				return 0;		
			}
		}
	}
	
	// The interactions for a normal person
	float agent_interaction_normal(MovingFestivalAgent other_agent) {
		switch other_agent.agent_type {
			match(AGENT_TYPE_NORMAL) {
				return 0;
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return 0;
			}
			match(AGENT_TYPE_CRIMINAL) {
				return 0;
			}
			match(AGENT_TYPE_JOURNALIST) {
				return 0;
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return 0;
			}
			default {
				return 0;		
			}
		}
	}
	
	// The interactions for a  party lover
	float agent_interaction_party_lover(MovingFestivalAgent other_agent) {
		switch other_agent.agent_type {
			match(AGENT_TYPE_NORMAL) {
				return 0;
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return 0;
			}
			match(AGENT_TYPE_CRIMINAL) {
				return 0;
			}
			match(AGENT_TYPE_JOURNALIST) {
				return 0;
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return 0;
			}
			default {
				return 0;		
			}
		}return 0;
	}

	// The interactions for a criminal
	float agent_interaction_criminal(MovingFestivalAgent other_agent) {
		switch other_agent.agent_type {
			match(AGENT_TYPE_NORMAL) {
				return 0;
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return 0;
			}
			match(AGENT_TYPE_CRIMINAL) {
				return 0;
			}
			match(AGENT_TYPE_JOURNALIST) {
				return 0.2;
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return 0;
			}
			default {
				return 0;		
			}
		}
	}
	
	// The interactions for a journalist
	float agent_interaction_journalist(MovingFestivalAgent other_agent) {
		switch other_agent.agent_type {
			match(AGENT_TYPE_NORMAL) {
				return 0;
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return 0;
			}
			match(AGENT_TYPE_CRIMINAL) {
				return 0;
			}
			match(AGENT_TYPE_JOURNALIST) {
				return 0;
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return 0;
			}
			default {
				return 0;		
			}
		}
	}
	
	// The interactions for a security guard
	float agent_interaction_security_guard(MovingFestivalAgent other_agent) {
		switch other_agent.agent_type {
			match(AGENT_TYPE_NORMAL) {
				return 0;
			}
			match(AGENT_TYPE_PARTY_LOVER) {
				return 0;
			}
			match(AGENT_TYPE_CRIMINAL) {
				return 0;
			}
			match(AGENT_TYPE_JOURNALIST) {
				return 0;
			}
			match(AGENT_TYPE_SECURITY_GUARD) {
				return 0;
			}
			default {
				return 0;		
			}
		}
	}	
	
	reflex update_location_happiness when: agent_state = AGENT_STATE_ACTIVE {
		float accumulated_happiness <- 0.0;
		
		list<MovingFestivalAgent> closeby_agents <- MovingFestivalAgent at_distance 5 where (each.agent_state = AGENT_STATE_ACTIVE);
		
		
		loop other_agent over: closeby_agents {
			accumulated_happiness <- accumulated_happiness + interact_with_agent(other_agent);
		}
		
		accumulated_happiness <- accumulated_happiness + interact_with_location();
		
		agent_current_happiness <- accumulated_happiness / (length(closeby_agents) + 1);
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

