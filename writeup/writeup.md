# Remake Writeup

### Background
*Centipede* was released in 1981 for the Atari 2600 and remains iconic in the video game industry. This game involves a player character named the “bug blaster” that defends against a segmented centipede that travels down the screen towards the player. When the player shoots a middle segment of the centipede, it splits into two separate parts, each continuing its own path toward the player. The game’s mechanics also include mushrooms left behind after each segment is destroyed, adding obstacles that change the centipede’s path and block the player’s line of sight, making it harder to shoot the enemy. Alongside the centipede, additional enemies such as spiders, scorpions, and fleas present different threats. Spiders move in zigzag patterns and attack the player. Scorpions travel horizontally across the screen turning any mushrooms they touch into poisonous mushrooms. Lastly, fleas drop from the top of the screen leaving trails of mushrooms. The game’s design combines fast paced action with escalating difficulty that requires both skill and strategy from the player.

### Goal/Objective
The objective for our project was to create a gameplay experience that mimics the original version of *Centipede* while adapting it to the constraints of TIC-80, a fantasy computer for making, sharing, and playing small games. Our remake aims to capture the core mechanics of *Centipede* while also adding some of our own twists to make the game better looking and a little easier. Specifically, this included developing the key features of the game such as player controlled movement and shooting, a segmented centipede that makes its way down the screen, mushrooms that populate the playfield, and a spider enemy with fast and unpredictable movement patterns. The scoring system was another key aspect we wanted to include in our remake.
The player’s movement was mapped to the TIC-80’s controller, allowing for movement in four directions within the lower third of the screen. The shooting mechanism was implemented with a timer in order to have a constant fire rate. For most elements in our game, we used tables to keep track of everything. For example, the player character has a table with x and y coordinates to keep track of their position on the screen, and a bullets table to store active bullets and track their positions. When the player fires, each bullet gets added to the bullet table and moves up the screen until it either hits an enemy or reaches the end of the screen. 

### Implementation
Centipedes was a table consisting of each centipede, which was stored as a table of segments, and each segment was a table with x, y coordinates and a direction variable to control movement. Each segment moves horizontally until it hits the edge of the screen or a mushroom, where it then shifts down and reverses direction. This replicates its movement in the original game, where it moves predictably but is still hard to keep track of with the addition of mushrooms and the splitting mechanic. When a segment is shot, it’s removed from the table. If a middle segment is shot the centipede splits into two new centipedes. This split is handled in the check_bullet_and_centipede_collision function, where the code copies the segments on either side of the shot segment into two new centipede tables.

We also designed the spider with a table and made it jump like in the original game. We used a timer with a random value within an interval to control how high the spider jumps each time. We also made it choose a random direction to jump each time to create a more unpredictable movement pattern. Additionally, within the check_spider_and_mushroom_collision function, we added roughly 25% chance that the spider would eat any mushroom it touches.

For scoring, different actions award points, like shooting centipede segments, spiders, and destroying mushrooms. Each spider kill awards either 300, 600, or 900 points depending on the distance it was shot from. Additionally, the player is awarded 100 points for shooting an end segment of a centipede, but only 10 points for a middle segment, thus incentivizing the player to aim carefully and time their shots. Lastly the player is awarded 1 point for each mushroom they destroy. 
The player starts the game with three lives and loses a life each time they come into contact with any enemy.

Finally, mushrooms are stored in a table, with each mushroom being its own table consisting of three variables, an x, y, and a health variable. In the original game, each mushroom takes four shots to destroy. However, in our game, we chose to set the health to two, since four felt like too many given the size of the payfield.

Each level’s completion depends on eliminating all centipede segments. When a level is cleared, a new centipede is created, more mushrooms are added, and the colors of the game elements change. To increase the difficulty, the spider’s speed increases once the player passes the first 5 levels. This coupled with a more populated mushroom field makes the game progressively harder as the player advances through the game.

### Challenges
One significant challenge was managing collision detection for multiple objects. The centipede, mushrooms, bullets, and spider all required individual and cross collision checks. For example, mushroom and centipede, mushroom and bullet, mushroom and spider, player and spider, player and centipede, bullet and centipede, and bullet and spider. For our collision functions, we looked at the “Bubbler Remake Code” [source](https://github.swarthmore.edu/pages/CS91S-S23/remake-ycho3-estutz1/), which helped us create our if statements when checking for a collision. In their code, they iterated through each enemy and compared their x and y coordinates while also taking into account the dimensions of the objects. For our game, we did the same thing. Also, we wanted it so that bullets would only impact one object per collision to prevent the bullet from passing through and hitting multiple objects. For this, we took inspiration from the “Tank Remake Source Code” [source](https://github.swarthmore.edu/pages/CS91S-S23/remake-aburges1-rcheruk1/), where they iterated through each bullet to check for a collision and remove the bullet if so. However, when checking for bullet collisions, we chose to iterate through the table backwards to prevent shifting when removing elements of the table.

One of the more complicated challenges we faced was accurately implementing the centipede's splitting behavior when being shot in a middle segment. In the original *Centipede* game, when a middle segment is hit, the centipede splits into two independently moving centipedes. Ensuring this mechanic required a lot of thought in our collision detection code for bullets and centipedes, as each split had to happen without disrupting the centipede’s movement pattern. At first, attempting to update segment movement directly after a split led to unexpected glitches between new_centipede1 and new_centipede2, such as overlapping segments or the wrong half switching direction. However, we were finally able to realize that instead of manually changing each segment in one of the new centipedes, we could leave them alone. We were able to do this by changing the destroyed segment into a mushroom at the same location. This made it so that the trailing centipede would always come in contact with the mushroom and perform direction change correctly every time.

The spider’s unpredictable movement also required balancing. Ensuring that the spider could move randomly but also in the pattern of jumping diagonally and falling straight down was very challenging. At first, we tried moving it in a random x and a random y direction every frame, however this did not achieve the outcome we wanted. After several experiments, we finally came to a method that worked.

### Conclusion 
Creating our own version of *Centipede* was a rewarding challenge that taught us a lot about game design. I gained a deeper appreciation for the mechanics that make classic atari games fun and engaging. Things like coding the centipede’s movement and figuring out how to handle collisions required us to think critically and solve problems.We learned that even with simple graphics and mechanics, a well designed game takes a lot of effort to create. The process of developing this game improved our understanding of TIC-80 and Lua, and helped us understand how important it is to balance game elements.

## Sources:
Bubbler past remake code 
(https://github.swarthmore.edu/pages/CS91S-S23/remake-ycho3-estutz1/)


Tank past remake code
(https://github.swarthmore.edu/pages/CS91S-S23/remake-aburges1-rcheruk1/)

Lua style guide
(https://github.com/Olivine-Labs/lua-style-guide)

Sound effects lesson in TIC-80
(https://www.youtube.com/watch?v=q_6jmnvQwjM)

