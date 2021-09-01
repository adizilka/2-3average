
pragma solidity ^0.5.0;



/***
 * THE RULES OF THE GAME
 * 3 players pay an amount, bet_i made by player_i
 * t_average is defined as (2/9)*(bet1+bet2+bet3)
 * The player whose bet is closest to t_average gets all the money, f there is a tie the leads get the money
 * 
 * HOW TO PLAY THE GAME
 * To enter you must chosse a number- amount of money to bet in the game - _bet
 * You must also choose a random number between 1 and (2**100)/100- _rand
 * You send joinGame((_rand*100)+_bet)
 * You call canWeStart() until it returns true
 * When it returns true you send startTheGame(_bet, _rand, _addr) where _addr is the address of the wallet, 
 * and you pay _bet*factor with the function call
 * This function returns false if there was an error and true if all went fine
 * The contract automaticly pays the money as per the rules of the game
 * */


contract Game{
    uint256 constant factor = 1000000000000000000;
    bool public gameOn = false; //true iff the game is on- both players sent hash and are waiting for the results

    struct player{
        address payable addr; //the address of the wallet
        uint256 bet; //the player's bets
        bytes32 hashOfBet; //hash of (rand*100)+bet
        address messageOrigin; //the address of the server
        bool joined; // has the player joined
    }
    
    //keeping info on which address is which player
    mapping(address => player) public playerIndex; 
    
    address[3] lastWinners = [address(0), address(0),address(0)];

    player player1; 
    player player2;
    player player3;
    
    //returns true if adding the numbers doesn't cause overflow
    function canWeAdd(uint256 a, uint256 b) internal pure returns (bool) {
        uint256 c = a + b;
        if (c < a){
            return false;
        } 
        return true;
    }

    //returns true iff we can subtract a and b
    function canWeSub(uint256 a, uint256 b) internal pure returns (bool) {
        if (b > a){
            return false; 
        }
        return true;
        
    }

    //returns true if there is no overflow when multiplying a by b
    function canWeMul(uint256 a, uint256 b) internal pure returns (bool) {
        if (a == 0){ 
            return true;
        }
        uint256 c = a * b;
        if (c / a != b){ 
            return false;
        }
        return true;
        
    }

    //returns the absolute value of a
    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0){
            return uint256(-a);
        }
        return uint256(a);
    }

    
    //calculate (2/3) of the average of (num1, num2, num3)
    //returns -1 if there was an error
    function t_average(uint256 num1, uint256 num2, uint256 num3) public pure returns(int256){
        bool canWe = canWeAdd(num1, num2); //making sure we can add the first two numbers
        if (!canWe){ //if we cant
            return -1;
        }
        uint256 temp = num1 + num2;
        canWe = canWeAdd(temp, num3); //making sure we can add the third number
        if (!canWe){ //if we cant
            return -1;
        }
        temp = temp + num3;
        canWe = canWeMul(temp, 2); 
        if (!canWe){
            return -1;
        }
        temp = temp * 2; //calculate (2/9)(num1+num2+num3)
        temp = temp / 9;
        return int256(temp);
    }


    //becames true if both players sent the hash, and returns to false if someone sent an illegal request
    function canWeStart() public view returns(bool){
        return gameOn;
    }
    
    //join the first player
    function joinPlayer1(bytes32 hash, address addr) internal{
        player1.hashOfBet = hash;
        player1.messageOrigin = addr;
        player1.joined = true;
    }
    
    //join the second player
    function joinPlayer2(bytes32 hash, address addr) internal{
        player2.hashOfBet = hash;
        player2.messageOrigin = addr;
        player2.joined = true;
    }
    
    //join the third player
    function joinPlayer3(bytes32 hash, address addr) internal{
        player3.hashOfBet = hash;
        player3.messageOrigin = addr;
        player3.joined = true;
    }
    
//the server calls this function to add the player
    //accepts the hash of (random*100)+bet
    //adds the player if the game hasn't started yet
    //returns true if the player joined
    //returns false if there are already two player and the game is in motion
    function joinGame(bytes32 hash) public returns(bool){
        if (gameOn){ //the game alreaedy started
            return false;
        }
        if (player1.joined == false) { //no players are waiting
            playerIndex[msg.sender] = player1; //remember the address of the player
            joinPlayer1(hash, msg.sender);
            return true; //player joined
        }
        if (player2.joined == false){ //there is one player in the game
            if (msg.sender == player1.messageOrigin){ //we make sure no two players have the same address
                return false;
            }
            playerIndex[msg.sender] = player2; //remember the address of the player
            joinPlayer2(hash, msg.sender); //join the player
            return true; //the player has joined
        }
        if (player3.joined == false){ //there are 2 players in the game
            if (msg.sender == player1.messageOrigin || msg.sender == player2.messageOrigin ){ //again making sure it has a different address
                return false;
            }
            playerIndex[msg.sender] = player3; //remember the address of the player
            joinPlayer3(hash, msg.sender); //join the player
            gameOn = true; //three players are now in, the game is on
            return true; //the player has joined
        }
        return false; //we reach here if the are already 3 players in the game, so this player couldn't join
        
    }


    //returns 0 if all bets are equal
    //returns 1 if the first player is closer
    //returns 2 if the second player is closer
    //returns 3 if the third player was the closest
    //returns 12 if the first and second players are the closest, 13 if the first and third players are the closest
    //and 23 if the second and third players are the closest
    function findClosest(uint256 bet1, uint256 bet2, uint256 bet3, uint256 average) internal pure returns(uint256){

        uint256 diff1 = abs(int256(bet1) - int256(average));
        uint256 diff2 = abs(int256(bet2) - int256(average));
        uint256 diff3 = abs(int256(bet3) - int256(average));

        //find the smallest distance
        if (diff1 < diff2){ 
            if (diff1 <  diff3){
                return 1;
            }
            if (diff3 < diff1){
                return 3;
            }
            return 13;
        }
        if (diff2 < diff1){
            if (diff2 <  diff3){
                return 2;
            }
            if (diff3 < diff2){
                return 3;
            }
            return 23;
        }
        //so diff1 == diff2
        if (diff1 < diff3){
            return 12;
        }
        if (diff3 < diff1){
            return 3;
        }
        return 0; //they are all the same
    }
   
   
    //checks if the random is too big
    //returns 0 if it is too big, random * 100 if not
    function isRandTooBig(uint256 random) internal pure returns(uint256){
        bool canWe = canWeMul(100, random); //tries to calculate rand*100
        uint256 temp =  100 * random; 
        if (!canWe || temp > (2**100)){
            return 0;
        }
        canWe = canWeAdd(100, temp); //make sure we can add the bet without overflow, there shoudn't be a problem
        temp =  100 * temp; 
        if (!canWe){ 
            return 0;
        }
        return 1;
    }
    
    //accepts num of type uint256 and returns a string of the number
    function uintToString(uint256 _num) internal pure returns (string memory _uintAsString) {
        if (_num == 0) {
            return "0";
        }
        uint temp = _num;
        uint len;
        while (temp != 0){
            len++;
            temp /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint index = len - 1;
        while (_num != 0) {
            bstr[index--] = byte(uint8(48 + _num % 10));
            _num /= 10;
        }
        return string(bstr);
    }
    
    //checks the hash is sha256(number + 100 * rand)
    //returns false if rand is too big
    function checkHash(uint256 number, uint256 random, bytes32 hash) internal pure returns(bool){
        bool canWe = canWeMul(100, random);
        if (!canWe){ //there was an error
            return false;
        }
        uint256 temp = 100 * random; 
        canWe = canWeAdd(temp, number);
        if (!canWe){
            return false;
        }
        temp = temp + number; //adding the bet to (random*100)
        if (sha256(abi.encodePacked(uintToString(temp))) == hash){ //hashing the value
            return true; 
        }
        return false;
    }
    
    //accepts the number, the random, the hash, the address
    //returns true iff- 0 < number < 101, random is of the right size, the hash is sha256(number + 100 * random)
    function checkValsAreValid(uint256 number, uint256 random, bytes32 hash) internal pure returns(bool){ 
        if (number == 0 || number > 100){ //checks the number is in range 
            return false;
        }
        if (isRandTooBig(random) == 0){ //make sure the random is not too big
            return false;
        }
        return checkHash(number, random, hash); //checks the hash is valid
    }
    
   //pays the winner the money they won, returns the money the players paid if there was a tie
    function payTheWinner() internal{
        require(canWeAdd(player1.bet, player2.bet)); //no reason for this to fail, as both bet are between 0 and 100
        uint256 amount = player1.bet + player2.bet; //all the money paid
        require(canWeAdd(amount, player3.bet)); //no reason for this to fail
        amount = amount + player3.bet;
        
        int256 ave = t_average(player1.bet, player2.bet, player3.bet); //the average
        require(ave > 0); //shoudn't be a problem here
        uint256 winner = findClosest(player1.bet, player2.bet, player3.bet, uint256(ave)); //we calculate the winner
        
        if (winner == 1){ //player 1 won, gets the money from both
            lastWinners[0] = player1.addr;
            lastWinners[1] = lastWinners[2] = address(0);
            (player1.addr).transfer(amount);
        }
        if (winner == 2){ //player 2 won, gets the money from both
            lastWinners[0] = player2.addr;
            lastWinners[1] = lastWinners[2] = address(0);
            (player2.addr).transfer(amount);
        }
        if (winner == 3){ //player 2 won, gets the money from both
            lastWinners[0] = player3.addr;
            lastWinners[1] = lastWinners[2] = address(0);
            (player3.addr).transfer(amount);
        }
        if (winner == 0){ //all players bet the same, we return the money
            (player1.addr).transfer(amount/3);
            (player2.addr).transfer(amount/3);
            (player3.addr).transfer(amount/3);
            lastWinners[0] = player1.addr;
            lastWinners[1] = player2.addr;
            lastWinners[2] = player3.addr;
        }
        if (winner == 12){
            (player1.addr).transfer(amount/2);
            (player2.addr).transfer(amount/2);
            lastWinners[0] = player1.addr;
            lastWinners[1] = player2.addr;
            lastWinners[2] = address(0);
        }
        if (winner == 13){
            (player1.addr).transfer(amount/2);
            (player3.addr).transfer(amount/2);
            lastWinners[0] = player1.addr;
            lastWinners[1] = address(0);
            lastWinners[2] = player3.addr;
        }
        if (winner == 23){
            (player2.addr).transfer(amount/2);
            (player3.addr).transfer(amount/2);
            lastWinners[0] = address(0);
            lastWinners[1] = player2.addr;
            lastWinners[2] = player3.addr;
        }
    }
    
    //this function returns 0 if the owner of the address didn't win the last round,
    //1 if they did and 2 if there was a tie and the address belongs to one of the players who won
    function amITheLastWinner(address addr) public view returns(uint256){
        if (addr == lastWinners[0] || addr == lastWinners[1] || addr == lastWinners[2]){
            if (!(address(0) == lastWinners[0] || address(0) == lastWinners[1] || address(0) == lastWinners[2])){
                return 2;
            }
            return 1;
        }
        return 0;
    }
    
    //checks if player is the third to join
    function areEveryoneIn() internal view returns(bool){
        uint256 count = 0;
        if (player1.addr != address(0)){
            count += 1;
        }
        if (player2.addr != address(0)){
            count += 1;
        }
        if (player3.addr != address(0)){
            count += 1;
        }
        return (count == 3);
    }
    
    function cleanUp() internal{ //clean up after the game
        delete(playerIndex[player1.messageOrigin]);
        delete(playerIndex[player2.messageOrigin]);
        delete(playerIndex[player3.messageOrigin]);
        delete(player1);
        delete(player2);
        delete(player3);
        delete(gameOn);
    }
    
    function returnTheMoney() internal{ //returning the money to those who paid
        if (player2.bet > 0){ //if player1 already paid
            (player2.addr).transfer(player2.bet);
        }
        if (player1.bet > 0){ //if player 2 already paid
            (player1.addr).transfer(player1.bet);
        }
        if (player2.bet > 0){
            (player3.addr).transfer(player3.bet);
        }
    }
    
    //this function accepts the number, the random, the address of the wallet, and msg.value when called
    //check all the values are valid and the hash is correct
    //when the third player joined it calls the function that calculates the winner and pays them
    function startTheGame(uint256 number, uint256 random, address payable addr) public payable returns(bool){
        //checks the message we got is from one of our players

        if (msg.sender != player1.messageOrigin && msg.sender != player2.messageOrigin && msg.sender != player3.messageOrigin){
            if (msg.value > 0){
                addr.transfer(msg.value); //returning the money
                returnTheMoney(); //returning the money to players who paid
				cleanUp();
            }
            return false;
        }
        
        //if there are no three players in the game yet it means one of the players tried to pay and send the bet when they shoudn't have
        //the game must stop as now the bet was visible to everyone
        if (!canWeStart()){ 
            if (msg.value > 0){
                addr.transfer(msg.value); //returning the money to this player
                returnTheMoney(); //returning the money to those who played 
            }
            cleanUp(); //cleaning up
            return false;
        }
        player memory pl = player1;
        if (msg.sender == player2.messageOrigin){ //this message is from the second player
            pl = player2;
        }
        if (msg.sender == player3.messageOrigin){ //this message is from the third player
            pl = player3;
        }
        if (number*factor != msg.value){ //the bet was different from the amount paid, this makes the game invalid
            if (msg.value > 0){
                addr.transfer(msg.value); //returning the money
            }
            cleanUp();
            return false;
        }
        if (checkValsAreValid(number, random, pl.hashOfBet) == false){ //one or more of the values are off, the game is invalid
            if (msg.value > 0){
                addr.transfer(msg.value); //returning the money
            }
            //we want to return money to the other player, if they paid already
            returnTheMoney();
            cleanUp();
            return false;
        }
        //the values are valid
        if (msg.sender == player2.messageOrigin){
            player2.bet = number*factor;
            player2.addr = addr;
        }
        if (msg.sender == player1.messageOrigin){
            player1.bet = number*factor;
            player1.addr = addr;
        }
        if (msg.sender == player3.messageOrigin){
            player3.bet = number*factor;
            player3.addr = addr;
        }
        
        if(areEveryoneIn()){
            payTheWinner();
            cleanUp();
            return true;
        }
        return true;
    }

}


