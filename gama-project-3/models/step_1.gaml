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
		list<list<rgb>> row_list <- [];
		loop i from: 1 to: N
		{
			list<rgb> row <- [];
			
			loop j from: 1 to: N
			{
				row << (((i + j) mod 2) = 0) ? #black : #white;
			}
			row_list << row;
			
		}
		list<rgb> row <- [];
		loop i from: 1 to: N
		{
			row << #yellow;
		}
		row_list << row;
		
		write row_list;
		
		ask cell
		{
			color <- row_list[grid_y][grid_x];
		}
		
		int current_id <- 0;
		create queen number: N
		{
			id <- current_id;
			current_id <- current_id + 1;
			
			col <- N;			
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


species queen
{
	float size <- 20.0 / N;
	int id;
	int col;
	
	aspect default {
		location <- cell[N * col + id].location;
		draw circle(size) color: #blue;
	}
}

grid cell width: N height: N + 1 neighbors: 4
{
}

experiment main type: gui
{
	output
	{
		display main_display
		{
			grid cell lines: #black;
			species queen; 
		}
	}

}