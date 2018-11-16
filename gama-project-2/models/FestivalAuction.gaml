/**
* Name: FestivalAuction
* Author: hrabo
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model FestivalAuction


global {
	init
	{
		// Make sure we get consistent behaviour
		seed<-10.0;
				
		create AuctionHall number: 1 {
			location <- {rnd(100), rnd(100)};
		}
		
		create FestivalGuest number: 10
		{
			location <- {rnd(100),rnd(100)};
			auction_hall <- first(1 among AuctionHall);
		}
		
		int add_location <- 0;
		create SpawnPoint number: 2 {
			location <- {50, 10 + add_location};
			add_location <- add_location + 80;
		}
		
		create FestivalAuctioneer number: 1
		{
			location <- first(SpawnPoint).location;
			auction_hall <- first(1 among AuctionHall);
		}
	}
}

/* Insert your model definition here */
species AuctionHall skills: [] {
	rgb myColor <- #yellow;
	
	aspect default{
    	draw square(10) at: {location.x, location.y} color: myColor;
    }
}

species FestivalAuctioneer skills: [moving, fipa] {
	rgb myColor <- #blue;
	AuctionHall auction_hall;
	
	int go_to_auction_timeout <- rnd(250) update: go_to_auction_timeout - 1 min: 0;
	
	int start_price <- 100 + rnd(500);
	int lowest_price <- round(start_price * 0.5);
	int current_price <- start_price;
	
	bool auction_active <- false;
	int auction_start_timeout <- 0 update: auction_start_timeout - 1 min: 0;
	
	list<FestivalGuest> agreed_buyers;
	
	reflex go_to_auction when: go_to_auction_timeout <= 0
	{
		if (location distance_to auction_hall > 4) {
			do goto target:auction_hall;
		}
	}
	
	reflex inform_about_auction when: location distance_to auction_hall < 2 and not auction_active
	{
		list<FestivalGuest> participants <- list<FestivalGuest> (FestivalGuest);
		do start_conversation(
			to: participants, protocol: 'fipa-inform', 
			performative: 'inform', 
			contents: ['Starting Auction', auction_hall]
		);
		
		auction_active <- true;
		auction_start_timeout <- 100;
	}
	
	reflex add_agreed_buyer when: !empty(informs)
	{
		loop a over: informs {
			write a.contents;
//			if (a.contents at 0 = 'Accept Auction')
//			{
//				agreed_buyers << a.sender;
//			}
		}
	}
	
	reflex start_auction when: location distance_to auction_hall < 2 and auction_active and auction_start_timeout <= 0
	{
		// Who is here?
		list<FestivalGuest> participants <- list<FestivalGuest> (FestivalGuest); // at_location auction_hall.envelope; 
		
		do start_conversation(
			to: participants, protocol: 'fipa-contract-net', 
			performative: 'cfp', 
			contents: ['Sell for price: ' + current_price]
		);
	}
	
	aspect default{
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
    }
}

species FestivalGuest skills: [moving, fipa] {
	rgb myColor <- #red;
	AuctionHall auction_hall;
	
	reflex go_to_auction
	{
		if (location distance_to auction_hall > 4) {
			do goto target:auction_hall;
		}
	}
	
	reflex answer_auction when: !empty(informs)
	{
		loop info over: informs
		{
			write info.contents;
//			if (info.contents at 0 = 'Starting Auction')
//			{
//				
//			}
		}
	}
	
	aspect default{
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
    }
}

species SpawnPoint {
	rgb myColor <- #purple;
	
	aspect default {
		draw sphere(5) at: location color: myColor;
	}
}

/*Running the experiment*/
experiment main type: gui {
	output {
		display map type: opengl 
		{
			species FestivalGuest;
			species FestivalAuctioneer;
			species AuctionHall;
			species SpawnPoint;
		}
//		display chart refresh:every(10.0)
//		{
//			chart "Agent information" type: series
//			{	
//				data "Avg. Moved Distance" value: (FestivalGuest sum_of(each.total_active_moved_distance)) / (time + 1);
//			}
//		}
	}
}
