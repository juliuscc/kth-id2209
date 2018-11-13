/**
* Name: FestivalGuest
* Author: hrabo, jcelik
* Description: 
* Tags: 
*/

model Festival

global {
	init
	{
		// Make sure we get consistent behaviour
		seed<-10.0;
		time<-0.0;
		
		create FestivalGuest number: 10
		{
			location <- {rnd(100),rnd(100)};
		}
				
		bool make_drink_store <- true;
		create FestivalStore number: 4
		{
			location <- {rnd(100), rnd(100)};
			
			if (make_drink_store)
			{
				hasDrinks <- true;
				hasFood <- false;
				myColor <- #purple;
				
			} else {
				hasDrinks <- false;
				hasFood <- true;
				myColor <- #green;
			}
			
			make_drink_store <- not make_drink_store;
		}
		
		create FestivalInformationCenter number: 1
		{
			location <- {50, 50};
		}
	}
}

species FestivalStore {
	rgb myColor <- #blue;
	
	bool hasDrinks <- false;
	bool hasFood <- false;
	
	aspect default{
		draw cube(10) at: location color: myColor ;
    }
}

species FestivalInformationCenter {
	rgb myColor <- #yellow;
	
	list<FestivalStore> drink_stores;
	list<FestivalStore> food_stores;
	
	init {
		ask FestivalStore {
			if (self.hasDrinks) {
				myself.drink_stores << self;
			}
			if (self.hasFood) {
				myself.food_stores << self;
			}
		}
	}
	
	aspect default{
		draw pyramid(10) at: location color: myColor ;
    }
    
}

species FestivalGuest skills: [moving] {
	rgb myColor <- #red;
	int max_food_and_drink_level <- 100;
	
	float drunkness <- 0.0 update: drunkness - 0.05 min: 0.0;
	bool drunk <- false;
	
	float total_active_moved_distance <- 0.0;
	
	FestivalStore target_store;
	point target_point;
	
	bool use_mem <- false;
	
	int drink_level <- rnd(max_food_and_drink_level);
	int food_level <- rnd(max_food_and_drink_level);
	
	list<FestivalStore> mem_drink_stores;
	list<FestivalStore> mem_food_stores;
	
	reflex beIdle when:  drink_level > 0 and food_level > 0 and target_store = nil and target_point = nil and not drunk
	{
		myColor <- #red;
		do wander;
	}
	
	reflex beDrunk when: drunkness > 100 or drunk
	{
		if (not drunk)
		{
			write "" + self + " got drunk";
		}
		
		drunk <- true;
		mem_drink_stores <- [];
		mem_food_stores <- [];
		
		if (drunkness <= 0)
		{
			drunk <- false;
		}
	}
	
	reflex go_to_target when: target_store != nil
	{
		do goto target:target_store;
		ask FestivalStore at_distance 2 {
			if (self.hasDrinks) {
				myself.drink_level <- myself.max_food_and_drink_level;
				
				myself.drunkness <- myself.drunkness + rnd(50);
			}
			if (self.hasFood) {
				myself.food_level <- myself.max_food_and_drink_level;
			}
			
			// Reset with a new mem value. 
			// 25% chance that they will try to find a new place
			myself.use_mem <- flip(1);
		}
		
		if (drink_level > 0 and food_level > 0) {
			target_store <- nil;
			target_point <- {rnd(100), rnd(100)};
		}
		
		total_active_moved_distance <- total_active_moved_distance + location distance_to destination;
	}
	
	reflex go_to_dance_target when: drink_level > 0 and food_level > 0 and target_store = nil and target_point != nil
	{
		myColor <- #red;
		do goto target:target_point; 
	}
	
	reflex enter_dance_mode when: drink_level > 0 and food_level > 0 and target_store = nil and target_point != nil
	{
		if (location distance_to (target_point) < 2)
		{
			target_point <- nil;
		}	
	}
	
	reflex inquire_resource_location_mem when: (drink_level <= 0 or food_level <= 0) and (target_store = nil) and use_mem
	{
		// Do an internal lookup operation. Abort if it is not possible.
		if (drink_level <= 0)
		{
			if length(mem_drink_stores) > 0 {
				target_store <- first(1 among mem_drink_stores);
				myColor <- #blue;	
				write "" + self + " is going to drink.";
			} else {
				use_mem <- false;
				write "" + self + " could have gone directly to drink.";
			}
			
		} else if (food_level <= 0)
		{
			if length(mem_food_stores) > 0 {
				target_store <- first(1 among mem_food_stores);	
				myColor <- #blue;
				write "" + self + " is going to eat.";
			} else {
				use_mem <- false;
				write "" + self + " could have gone directly to food.";
			}
		}
		
	}
	
	// Make sure the agent will do something when it gets thirsty
	reflex inquire_resource_location when: (drink_level <= 0 or food_level <= 0) and (target_store = nil) and not use_mem
	{		
		myColor <- #yellow;
		
		// Do a lookup operation (go to information center)
		do goto target:{50,50};
		ask FestivalInformationCenter at_distance 2 {
			if(myself.drink_level <= 0) {
				int count <- length(self.drink_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.drink_stores[index];
				myself.myColor <- #purple;
				
				// Adding to mem. without duplicates
				remove all: myself.target_store from: myself.mem_drink_stores;
				add myself.target_store to: myself.mem_drink_stores;
				
			} else if (myself.food_level <= 0) {
				int count <- length(self.food_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.food_stores[index];
				myself.myColor <- #green;
				
				// Adding to mem. without duplicates
				remove all: myself.target_store from: myself.mem_food_stores;
				add myself.target_store to: myself.mem_food_stores;
			}

//			write self.food_stores;
//			write self.drink_stores;
		}
		
		total_active_moved_distance <- total_active_moved_distance + location distance_to destination;
	}
	
	// make more thirsty or hungry
	reflex consume_resources when: drink_level > 0 and food_level > 0 and not drunk
	{
		// More hunger
		if (flip(0.5)) {
			food_level <- food_level - 1;
		// More thirst
		} else {
			drink_level <- drink_level - 1;
		}
	} 
		
	aspect default{
		if (drunk and target_point = nil)
		{
			draw rotated_by(pyramid(3), 90, {1,0,0}) at: {location.x, location.y, 0} color: #black;
	    	draw sphere(1.5) at: {location.x, location.y+3, 0} color: #black;			
		} else
		{
			draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
	    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
		}
    }
}

/*Running the experiment*/
experiment main type: gui {
	output {
		display map type: opengl 
		{
			species FestivalGuest;
			species FestivalStore;
			species FestivalInformationCenter;
		}
		display chart refresh:every(10.0)
		{
			chart "Agent information" type: series
			{	
//				data "Avg. Moved Distance" value: (FestivalGuest sum_of(each.total_active_moved_distance)) / (time + 1);
				data "Avg. Drunkness / 10" value: (FestivalGuest sum_of(each.drunkness)) / (length(FestivalGuest) * 10);
				data "Nr Passed Out" value: length(FestivalGuest where each.drunk);
			}
		}
	}
}


