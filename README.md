# 2-3average
Our game-
We created a contract for the game "2/3 average", a simple game where a set of players send a bet each, and the winner is the player that guessed the number closest to the average of all the bets. 
In our contract there are 3 players.
The game goes as follows- the players are all connected to the same network, and enter our site. There they can enter a number between 1 and 100, and the site makes sure it is indeed a number of the correct size. The site then creates a big random number and sends the contract she256(100*random + _numberChosen).
This is the commitment of the value, as we want every player to stick to their bet and at the same time to keep the bets secret, as the game can be easily abused when the bets are visible. When all the players sent the hash, the game is on, and the site now sends the random, the bet, and bet*10^18 wei, and the address of the wallet of the players.
The contract checks all these values- that the hash is valid and that the correct amount of money was paid.
In case of any error in the values sent in this stage, the game shuts and restart, returning the players the money they paid. If all the values are valid, we find the closest player (or players in case of tie) and give them the money the game collected.



