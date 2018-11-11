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
				myColor <- #blue;
				
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
	
	point target_point;
	
	int drink_level <- rnd(10);
	int food_level <- rnd(10);
	
	reflex beIdle when: target_point = nil
	{
		do wander;
	}
	
	reflex go_to_target when: target_point != nil
	{
		if (location distance_to(target_point) < 2) {
			if (drink_level <= 0) {
				drink_level <- 10;
			} else {
				food_level <- 10;
			}
			
			target_point <- nil;
		} else {
			do goto target:target_point;
		}
	}
	
	// Make sure the agent will do something when it gets thirsty
	reflex inquire_resource_location when: (drink_level <= 0 or food_level <= 0) and (target_point = nil)
	{
		do goto target:{50,50};
		ask FestivalInformationCenter at_distance 2 {
			if(myself.drink_level <= 0) {
				int count <- length(self.drink_stores);
				int index <- rnd(count - 1);
				myself.target_point <- self.drink_stores[index].location;
			} else if (myself.drink_level <= 0) {
				int count <- length(self.food_stores);
				int index <- rnd(count - 1);
				myself.target_point <- self.food_stores[index].location;
			}
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
	
//	reflex changeColor when: !haveMet {
//		myColor <- flip(0.5) ? #red : #blue;
//	}
	
//	reflex goToPoint when: myColor = #red and !haveMet
//	{
//		do goto target:target_point speed: 3.0;
//		if(location distance_to(target_point ) < 3)
//		{
//			target_point <- {rnd(100),rnd(100)};
//		}
//	}
	
	aspect default{
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
//		if(!haveMet)
//    	{
//    		draw box(2,2,2) at: target_point color: #black;
//    		draw line([location,target_point]) color:#black;
//    	}
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


