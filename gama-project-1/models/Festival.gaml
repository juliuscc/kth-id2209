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
//		FestivalInformationCenter info_center <- nil
		
		
		create FestivalGuest number: 10
		{
			location <- {rnd(100),rnd(100)};
		}
				
		int add_dist <- 0;
		int d_dist <- 60;
		bool make_drink_store <- true;
		create FestivalStore number: 2
		{
			location <- {10 + add_dist, 10 + add_dist};
			add_dist <- add_dist + d_dist;
			
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
//			information_centers[1].addStore(self);
		}
		
		create FestivalInformationCenter number: 1
		{
			location <- {50, 50};
		}
	}
//	reflex globalPrint
//	{
//		write "Step of simulation: " + time;
//	}
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
		draw cube(10) at: location color: myColor ;
    }
    
}

species FestivalGuest skills: [moving] {
	rgb myColor <- #red;
	
	FestivalStore target_store;
	
	int drink_level <- rnd(100);
	int food_level <- rnd(100);
	
	reflex beIdle when: target_store = nil and (drink_level > 0 and food_level > 0)
	{
		myColor <- #red;
		do wander amplitude:100.0;
	}
	
	reflex go_to_target when: target_store != nil
	{
		do goto target:target_store;
		ask FestivalStore at_distance 2 {
			if (self.hasDrinks) {
				myself.drink_level <- 100;
			}
			if (self.hasFood) {
				myself.food_level <- 100;
			}
		}
		
		if (drink_level > 0 and food_level > 0) {
			target_store <- nil;
		}
	}
	
	// Make sure the agent will do something when it gets thirsty
	reflex inquire_resource_location when: (drink_level <= 0 or food_level <= 0) and (target_store = nil)
	{		
		myColor <- #yellow;
		
		do goto target:{50,50};
		ask FestivalInformationCenter at_distance 2 {
			if(myself.drink_level <= 0) {
				int count <- length(self.drink_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.drink_stores[index];
				myself.myColor <- #purple;
			} else if (myself.food_level <= 0) {
				int count <- length(self.food_stores);
				int index <- rnd(count - 1);
				
				myself.target_store <- self.food_stores[index];
				myself.myColor <- #green;
			}

			write self.food_stores;
			write self.drink_stores;
		}
	}
	
	// Enter store when we are close
//	reflex enter_store when: location distance_to(target_point) < 2
//	{
//	}
	
	// make more thirsty or hungry
	reflex consume_resources when: drink_level > 0 and food_level > 0
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
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
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
//		display chart
//		{
//			chart "Agent information"
//			{
//				data "Agents blue color" value:length(FestivalGuest where (each.myColor = #blue));
//				data "Have met another blue" value:length(FestivalGuest where (each.haveMet = true));
//			}
//		}
	}
}


