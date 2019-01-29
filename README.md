# ID2209 Distributed Artificial Intelligence and Intelligent Agents

All the project work in the course ID2209 Distributed Artificial Intelligence and Intelligent Agents on the Royal Institute of Technology (KTH). Among other things, we did a simulation of festival guests and behaviour with the help of reinforcement learning (Q-learning).

The agents succesfully learned how to create an enjoyable experience. An example is that the agents quickly learned to alternate drinking beer with water as they were more happy if their alcohol level was moderate, instead of agents being wasted. They also learned to congregate in locations that they prefered, where there preferable music genre was being played.

A short report of the project can be found here: [project report](/project-report.pdf)

<!-- ## Screenshots from simulation -->

## Q-Learning

The agents had a matrix called Q, that kept track of potential happiness gained from taking particular actions depending on the state of the environment. The rows represent a specific state and the columns represent a specific action.

<p align="center">
	<img src="images/Q_matrix.svg">
</p>

The Q-matrix was updated in every iteration. The new Q-value was calculated from the old one, the current happiness, as well as the potential happiness gained from taking the most prefered action considering the current state of the environment.

<p align="center">
	<img width="80%" src="images/Q_new.svg">
</p>
