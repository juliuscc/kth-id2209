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
		
		write row_list;
		
		ask cell
		{
			color <- row_list[grid_x][grid_y];
		}
		
		int current_id <- 0;
		create queen number: N
		{
			id <- current_id;
			current_id <- current_id + 1;
			
			location <- cell[id * N + id].location;
		}
	}

}

species queen
{
	float size <- 20.0 / N;
	int id;
	
	aspect default {
		draw circle(size) color: #blue;
	}
}

grid cell width: N height: N neighbors: 4
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