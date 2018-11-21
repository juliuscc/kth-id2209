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
//			auction_hall <- first(1 among AuctionHall);
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
	
	int go_to_auction_timeout <- rnd(100) update: go_to_auction_timeout - 1 min: 0;
	
	int start_price <- 100 + rnd(150);
	int current_price <- start_price;
	int auction_iteration <- 0;
	
	bool should_start_auction <- true;
	bool auction_active <- false;
	int auction_start_timeout <- 0 update: auction_start_timeout - 1 min: 0;
	
	int nr_buyers_ready <- 0;
	message last_agreed_message;
	bool there_exists_last_agreed_message <- false; // workaround for hack https://github.com/gama-platform/gama/issues/2573
	bool any_buyer <- true;
	
	list<FestivalGuest> agreed_buyers;
	
	reflex go_to_auction when: go_to_auction_timeout <= 0 and should_start_auction
	{
		if (location distance_to auction_hall > 2) {
			do goto target:auction_hall;
		}
	}
	
	reflex inform_about_auction when: location distance_to auction_hall <= 2 and not auction_active and should_start_auction
	{
		agreed_buyers <- [];
		auction_active <- true;
		should_start_auction <- false;
		auction_start_timeout <- 100;
		
		write "Informing about auction";
		list<FestivalGuest> participants <- list<FestivalGuest> (FestivalGuest);
		do start_conversation(
			to: participants, protocol: 'fipa-inform', 
			performative: 'inform', 
			contents: ['Starting Auction', auction_hall]
		);
	}
	
	reflex add_agreed_buyer when: !empty(informs)
	{
		loop info over: informs {
			write "New buyer: " + info.contents at 0;
			if (info.contents at 0 = 'Participate in Auction')
			{
				agreed_buyers << info.sender;
			}
		}
		
		informs <- [];
	}
	
	reflex start_auction 
		when: 		auction_active 
			and 	(auction_start_timeout <= 0 
			or 		(nr_buyers_ready = length(agreed_buyers) and nr_buyers_ready > 0))
		
	{
		
		auction_iteration <- auction_iteration + 1;
		
		if (any_buyer)
		{
			write "\n============================\nStarting auction iteration: " + auction_iteration;
			write "Sell for price: " + current_price;
			auction_start_timeout <- 100;
			nr_buyers_ready <- 0;
			
			do start_conversation(
				to: agreed_buyers, protocol: 'fipa-contract-net', 
				performative: 'cfp', 
				contents: ['Sell for price', current_price]
			);
			
			any_buyer <- false;	
		}
		else if(there_exists_last_agreed_message)
		{
			auction_active <- false;
								
			write "Agent [" + last_agreed_message.sender + "] will buy at price: " + current_price;	
			write "Item sold!";
			do accept_proposal with: (message: last_agreed_message, contents: ['Item sold to you at price', current_price]);
			
			// Reject all others
			loop proposition over: proposes {
				do reject_proposal with: (message: proposition, contents: ['Item already sold']);
			}
			
		}
		else
		{
			auction_active <- false;
			write "No one is willing to buy at the right price.";
			
			do start_conversation(
				to: agreed_buyers, protocol: 'fipa-inform', 
				performative: 'inform', 
				contents: ['Auction Ended', auction_hall]
			);
		}
		
		if (auction_iteration > 1)
		{
			current_price <- round(current_price * 1.1);
		}
	}
	
	reflex collect_failures when: !empty(failures)
	{
		write "Failue in communication protocol! Removing participant!";
		loop wrongdoerMessage over: failures
		{
			remove wrongdoerMessage.sender from: agreed_buyers;	
		}
		
		failures <- [];
	}
	
	reflex collect_accepts when: !empty(proposes)
	{
		message winnerMessage <- first(1 among proposes);
		last_agreed_message <- winnerMessage;
		there_exists_last_agreed_message <- true;
		
		// Delete all messages
		loop proposition over: proposes
		{
			let temp <- proposition.contents;
		}
		
		any_buyer <- true;
	}
	
	reflex collect_refusals when: !empty(refuses)
	{
		loop refuser over: refuses
		{
			write "Agent ["+refuser.sender+"] refuses with message: " + refuser.contents;
			nr_buyers_ready <- nr_buyers_ready + 1;
		}
		refuses <- [];
	}
	
	reflex go_back when: not should_start_auction and not auction_active
	{
		do goto target: SpawnPoint[0].location;
		
		if location distance_to SpawnPoint[0].location <= 0
		{
			do die;
		}
	} 

	aspect default {
		draw pyramid(3) at: {location.x, location.y, 0} color: myColor;
    	draw sphere(1.5) at: {location.x, location.y, 3} color: myColor;
	}
}

species FestivalGuest skills: [moving, fipa] {
	rgb myColor <- #red;
	AuctionHall auction_hall;
	point target_point;
	int accepted_price <- 100 + rnd(100);
	
	reflex go_to_auction when: auction_hall != nil
	{
		if (location distance_to auction_hall > 2) {
			do goto target:auction_hall;
		}
	}
	
	reflex go_to_target_point when: target_point != nil
	{
		do goto target:target_point;
		
		if location distance_to target_point < 2
		{
			target_point <- nil;
			
			if (myColor = #green) {
				do die;
			}
		}
	}
	
	// Selects an auction when a new auctioneer comes.
	reflex answer_auction when: !empty(informs) and auction_hall = nil
	{
		loop info over: informs
		{
			if (info.contents at 0 = "Starting Auction")
			{
				write "["+info.contents at 0+"] Selecting auction: " + info.contents at 1;
				auction_hall <- info.contents at 1;
				
				// Inform about participation
				do start_conversation(
					to: info.sender, protocol: 'fipa-inform', 
					performative: 'inform', 
					contents: ['Participate in Auction']
				);
			}
		}
		
		informs <- [];
	}
	
	reflex win_auction when: !empty(accept_proposals)
	{
		loop accepted_proposals over: accept_proposals
		{
			if (accepted_proposals.contents at 0 = 'Item sold to you at price')
			{
				write "["+self+"] I won the auction";
				myColor <- #green;
				target_point <- SpawnPoint[1].location;
			}
		}
	}
	
	// Selects an auction when a new auctioneer comes.
	reflex end_auction when: !empty(informs) and auction_hall != nil
	{
		loop info over: informs
		{
			if (info.contents at 0 = 'Auction Ended' and info.contents at 1 = auction_hall)
			{
				write "["+self+"] Leaving auction";
				auction_hall <- nil;
				if (myColor != #green) {
					target_point <- {rnd(100), rnd(100)};
				}
			}	
		}	
	}
	
	reflex auction_request when: !empty(cfps)
	{
		message proposalFromAuctioneer <- cfps[0];
		
		if (proposalFromAuctioneer.contents at 0 = 'Sell for price')
		{
			int proposedPrice <- proposalFromAuctioneer.contents at 1;
			if (proposedPrice < accepted_price)
			{
				// Accept
				write "["+self+"] Accepting price: " + proposedPrice + " would accept at " + accepted_price;
				do propose with: (message: proposalFromAuctioneer, contents: ['Accept price', proposedPrice]);
			}
			else
			{
				// Refuse
				write "["+self+"] Refusing price: " + proposedPrice + " would accept at " + accepted_price;
				do refuse with: (message: proposalFromAuctioneer, contents: ['Does not accept price', proposedPrice]);
				write "["+self+"] Leaving auction";
				auction_hall <- nil;
				if (myColor != #green) {
					target_point <- {rnd(100), rnd(100)};
				}
			}
		}
		else
		{
			write "Received wrong message: " + proposalFromAuctioneer.contents;
			do failure with: (message: proposalFromAuctioneer, contents: ['Did not understand message']);
		}
		
		cfps <- [];
	}
	
	aspect default {
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
