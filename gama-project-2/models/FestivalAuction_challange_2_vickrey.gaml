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
	
	int lowest_price <- round(rnd(300) * 0.5);
	
	bool should_start_auction <- true;
	bool auction_active <- false;
	int auction_start_timeout <- 0 update: auction_start_timeout - 1 min: 0;
	
	bool start_message_sent <- false;
	
	int nr_of_bids <- 0;
	int highest_bid <- 0;
	int second_highest_bid <- 0;
	bool has_higest_bid <- false;
	message highest_bidder_message <- nil;
	
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
			when: 	auction_active 
			and 	auction_start_timeout <= 0
			and 	not start_message_sent 
	{
		write "Starting auction";
		start_message_sent <- true;
		auction_start_timeout <- 100;
		nr_of_bids <- 0;
		
		do start_conversation(
			to: agreed_buyers, protocol: 'fipa-contract-net', 
			performative: 'cfp', 
			contents: ['Selling Item']
		);	
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
			
		// Reject all others
		loop proposition over: proposes {
			
			write "Agent ["+proposition.sender+"] want to buy at price: " + proposition.contents at 1;	
			nr_of_bids <- nr_of_bids + 1;
			
			if (highest_bid < (proposition.contents at 1 as int)) 
			{
				second_highest_bid <- highest_bid;
				highest_bid <- proposition.contents at 1 as int;
				
				write "New highest bid: " + highest_bid + " by " + proposition.sender;
				
				if (has_higest_bid)
				{
					write "Rejecting " + highest_bidder_message.sender;
					do reject_proposal with: (message: highest_bidder_message, contents: ['Item sold to another user']);
				}
				
				has_higest_bid <- true;
				highest_bidder_message <- proposition;
			}
			
			// End of auction.
			if (nr_of_bids >= length(agreed_buyers))
			{
				auction_active <- false;
				
				if(agreed_buyers != nil)
				{
					write "Higest bid: " + highest_bid + " (lowest accepted: " + lowest_price + ")";
					if (highest_bid >= lowest_price)
					{
						write "Accepting price: " + highest_bid + " for agent: " + highest_bidder_message.sender;
						do accept_proposal with: (message: highest_bidder_message, contents: ['Item sold to you at price', highest_bid]);
					}
					else
					{
						write "Did not accept any bids";
						do reject_proposal with: (message: highest_bidder_message, contents: ['Item sold to another user']);
					}

					write "Stopping auction";
					do start_conversation(
						to: agreed_buyers, protocol: 'fipa-inform',
						performative: 'inform',
						contents: ['Auction Ended', auction_hall]
					);
					
					agrees <- [];
					agreed_buyers <- [];
				}	
			}
		}
	}
	
	reflex collect_refusals when: !empty(refuses)
	{
		loop refuser over: refuses
		{
			write "Agent ["+refuser.sender+"] refuses to participate: " + refuser.contents;
			remove refuser.sender from: agreed_buyers;
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
		
		if (proposalFromAuctioneer.contents at 0 = 'Selling Item')
		{
			write "["+self+"] Proposing price: " + accepted_price;
			do propose with: (message: proposalFromAuctioneer, contents: ['Accept price', accepted_price]);
			

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
