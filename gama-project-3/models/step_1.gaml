/***
* Name: step1
* Author: jcelik
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model step1

global
{
	int N <- 5;
	
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
	
	reflex get_activated when: !(empty(proposes))
	{
		message proposalFromInitiator <- proposes at 0;
		positions <- proposalFromInitiator.contents at 0;
	
		int i <- 0;
		loop position over: positions
		{
			
		}
	
//		loop i from: 0 to: N
//		{
//			bool same_col <- positions contains i;
//			bool diagonal <- false;
//			
//			int i <- 0;
//			loop position over: positions
//			{
//				delta_col <- position - i; 
//				delta_row <- i - id;
//				
//				i <- i + 1;
//			}
//		}



		positions << row;
		
		write positions;
	}
	
	aspect default {
		location <- Cell[N * row + id].location;
		draw circle(size) color: #blue;
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