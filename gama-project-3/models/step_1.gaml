/***
* Name: step1
* Author: jcelik
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model step1

global
{
	int N <- 15;
	
	init
	{
		list<list<rgb>> col_list <- [];
		loop i from: 1 to: N
		{
			list<rgb> col <- [];
			
			loop j from: 1 to: N
			{
				col << (((i + j) mod 2) = 0) ? #black : #white;
			}
			col_list << col;
			
		}
		list<rgb> col <- [];
		loop i from: 1 to: N
		{
			col << #yellow;
		}
		col_list << col;
				
		ask Cell
		{
			color <- col_list[grid_y][grid_x];
		}
		
		int current_id <- 0;
		create Queen number: N
		{
			id <- current_id;
			current_id <- current_id + 1;
			
			row <- N;
		}
	}

}

/*
 * 
 * States:
 * 1. Waiting for predecessor to activate me.
 * 2. Getting activated and:
 *   i ) Place itself on possible location, and then activate descendant.
 *   ii) Inform predecessor that placement is impossible.
 * 3. Be placed on board.
 * 4. Have to be re-placed as descendent has no viable placements.
 * 
 */


species Queen skills: [fipa]
{
	float size <- 20.0 / N;
	int id;
	int row;
	message proposalFromInitiator;
	rgb myColor <- #blue;
	
	bool unread_proposal <- false;
	
	list<int> positions <- [];
	
	reflex place_first when: time = 0 and id = 0
	{
		row <- 0;
		positions << row;
		
		do start_conversation(
			to: [Queen[id + 1]],
			protocol: 'fipa-propose',
			performative: 'propose',
			contents: [positions]
		);
	}
	
	reflex get_activated when: unread_proposal
	{
		unread_proposal <- false;
		
		proposalFromInitiator <- proposes at 0;
		positions <- [];
		loop position over: (proposalFromInitiator.contents at 0)
		{
			positions << int(position);
		}
		
	
	
		list<bool> possible_positions <- list_with(N, true);
				
		int i <- 0;
		loop position over: positions
		{
			loop j from: 0 to: N - 1
			{
				int delta_col <- abs(i - id);
				int delta_row <- abs(position - j);
				
				if (delta_col = 0 or delta_row = 0)
				{
					possible_positions[j] <- false;
				}
				else if (delta_col = delta_row)
				{
					possible_positions[j] <- false;
				}
			}
			
			i <- i + 1;	
		}
			
		if (possible_positions contains true)
		{
			row <- possible_positions index_of true;
			positions << row;
			
			if (id < N - 1)
			{
				do start_conversation(
					to: [Queen[id + 1]],
					protocol: 'fipa-propose',
					performative: 'propose',
					contents: [positions]
				);	
			}
			else
			{
				myColor <- #green;
				do accept_proposal with: (message: proposalFromInitiator, contents: []);
			}
		}
		else
		{
			do reject_proposal with: (message: proposalFromInitiator, contents: []);
		}
	}
	
	reflex finished when: !(empty(accept_proposals))
	{
		message accept <- accept_proposals at 0;
		let temp <- accept.contents;
		
		myColor <- #green;
		if (id > 0)
		{
			do accept_proposal with: (message: proposalFromInitiator, contents: []);
		}
		else
		{
			write "Simulation finished!";
		}
	}
	
	reflex update_position when: !(empty(reject_proposals))
	{		
		message rejection <- reject_proposals at 0;
		let temp <- rejection.contents;
		
		list<bool> possible_positions <- list_with(N, true);
		if (row < N - 1) {
			loop i from: 0 to: row
			{
				possible_positions[i] <- false;
			}
			
			positions >- length(positions) - 1;
			
			int i <- 0;
			loop position over: positions
			{
				loop j from: row + 1 to: N - 1
				{
					int delta_col <- abs(i - id);
					int delta_row <- abs(position - j);
					
					if (delta_col = 0 or delta_row = 0)
					{
						possible_positions[j] <- false;
					}
					else if (delta_col = delta_row)
					{
						possible_positions[j] <- false;
					}
				}
				
				i <- i + 1;
			}
			
		}
		else
		{
			possible_positions <- list_with(N, false);
		}
		
		if (possible_positions contains true)
		{
			row <- possible_positions index_of true;
			positions << row;
			
			do start_conversation(
				to: [Queen[id + 1]],
				protocol: 'fipa-propose',
				performative: 'propose',
				contents: [positions]
			);
		}
		else
		{
			do reject_proposal with: (message: proposalFromInitiator, contents: []);
		}
	}
	
	reflex update_proposals when: !(empty(proposes))
	{
		unread_proposal <- true;
	}
	
	aspect default {
		location <- Cell[N * row + id].location;
		draw circle(size) color: myColor;
	}
}

grid Cell width: N height: N + 1 neighbors: 4
{
}

experiment main type: gui
{
	output
	{
		display main_display
		{
			grid Cell lines: #black;
			species Queen; 
		}
	}

}