App = {
  loading: false,
  contracts: {},

  load: async () => {
    await App.loadWeb3()
    await App.loadAccount()
    await App.loadContract()
    await App.render()
	web3.eth.defaultAccount = web3.eth.accounts[0];
	
	//const result = await App.game.startTheGame.call(0,0,0); //to clean the server
	//await App.game.startTheGame(0,0,0); //to clean the server
	
	const error1 = $('#error1')
	const text1 = $('#your_number')
	const text2 = $('#starting')
	const text3 = $('#game_taken')
	error1.hide()
	text1.hide()
	text2.hide()
	text3.hide()
		
	
  },

  // https://medium.com/metamask/https-medium-com-metamask-breaking-change-injecting-web3-7722797916a8
  loadWeb3: async () => {
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider
      web3 = new Web3(web3.currentProvider)
    } else {
      window.alert("Please connect to Metamask.")
    }
    // Modern dapp browsers...
    if (window.ethereum) {
      window.web3 = new Web3(ethereum)
      try {
        // Request account access if needed
        await ethereum.enable()
        // Acccounts now exposed
        web3.eth.sendTransaction({/* ... */})
      } catch (error) {
        // User denied account access...
      }
    }
    // Legacy dapp browsers...
    else if (window.web3) {
      App.web3Provider = web3.currentProvider
      window.web3 = new Web3(web3.currentProvider)
      // Acccounts always exposed
      web3.eth.sendTransaction({/* ... */})
    }
    // Non-dapp browsers...
    else {
      console.log('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  },

  loadAccount: async () => {
    // Set the current blockchain account
    App.account = web3.eth.accounts[0]
  },

  loadContract: async () => {
	// Create a JavaScript version of the smart contract
    const game = await $.getJSON('Game.json')
    App.contracts.Game = TruffleContract(game)
    App.contracts.Game.setProvider(App.web3Provider)

    // Hydrate the smart contract with values from the blockchain
    App.game = await App.contracts.Game.deployed()
	//GAME =  await new window.web3.eth.Contract(App.game.abi,App.game.address)
  },

  render: async () => {
    // Prevent double render
    if (App.loading) {
      return
    }

    // Update app loading state
    App.setLoading(true)

    // Render Account
    $('#account').html(App.account)


    // Update loading state
    App.setLoading(false)
  },

  
  startGame: async () => {
	 //set
    App.setLoading(true)
	const sleep = (delay) => new Promise((resolve) =>setTimeout(resolve,delay))
	const error1 = $('#error1')
	error1.hide()
	
	//getting the number of the user
    const content = $('#newTask').val()
	const num_content = parseInt(content)
	console.log("num"+num_content)
	
	//check if the number is a number!
	if (isNaN(num_content)){
		//if not a number, write error and reset the game.
		App.setLoading(false)
		const error1 = $('#error1')
		error1.show()
		console.log("heyy")
		await App.render()
		return;
		
		
	}
	//check if the number is between 1 and 100, if no return error
	if (num_content<1 || num_content>100){
		App.setLoading(false)
		const error1 = $('#error1')
		error1.show()
		await App.render()
		return;
		
	}
	//update the website 
	document.getElementById("your_number").innerHTML ="You chose the number "+ num_content
	const text1 = $('#your_number')
	text1.show()
	
	//our algorithem!!
	//choose random : sent_number = rand*100+number
	const rand = Math.floor(Math.random() * 100000000000000);
	var sum =rand*100 + num_content
	var sum = ""+sum
	console.log("rand= "+rand*100+"sum "+sum)
	
	
	
	//hash the final number (sum)
	var hash ="0x"+CryptoJS.SHA256(""+sum);
	const msgBuffer = new TextEncoder().encode(sum);
	const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
	const hashArray = Array.from(new Uint8Array(hashBuffer));
	const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
	console.log("hash"+hashHex)
	hash= "0x"+hashHex
	console.log("hash "+hash)

	//try joining the game
	join = await App.game.joinGame.call(hash)
	await App.game.joinGame(hash)
	console.log("join: "+join)

	//check if joining faled
	if ( join == false){
		//print error - game is taken!!
		text1.show()
		console.log("game is taken...")
		const text3 = $('#game_taken')
		document.getElementById("game_taken").innerHTML ="there are already 3 peaple playing..., max waiting time is 55 seconds "
		text3.show()
		console.log(await App.game.canWeStart())
		//wait for game to be free, or clean it if it takes to long
		for (let i = 55; i > 0; i--){
			if(!(await App.game.canWeStart())){ //if game is ready
				text3.hide()
				App.setLoading(false)
				await App.render()
				return;
			}
			document.getElementById("game_taken").innerHTML ="there are already 3 peaple playing..., max waiting time is "+i+" seconds "
			await sleep(1000)
		}
		const result = await App.game.startTheGame.call(0,0,0); //to clean the server
		await App.game.startTheGame(0,0,0); //to clean the server		App.setLoading(false)
		await App.render()
		return;
	}
	
	//print that we are now waiting for opponent
	const text2 = $('#starting')
	document.getElementById("starting").innerHTML ="wainting for apponent "
	text2.show()

	//waiting for opponent 
	var start = false
	for (let i = 0; i < 50; i++) {
		//check if opponent is in the game
		start = await App.game.canWeStart()
		if (start){ //ready, move on
			console.log("start"+await App.game.canWeStart())
			break;
		}
		document.getElementById("starting").innerHTML ="wainting for apponent "+ i
		await sleep(1000)
		console.log(i)
	}
	//done waiting!
	if (!start){//no opponent found...
		document.getElementById("starting").innerHTML ="no apponent found.. try again"
		console.log("you are alone...")
		const result = await App.game.startTheGame.call(0,0,0); //to clean the server
		await App.game.startTheGame(0,0,0); //to clean the server
		App.setLoading(false)
		await App.render()
		return;
	} 
	else{//opponent found!
		//starting game:
		document.getElementById("starting").innerHTML ="found opponnent, starting game! loading..."
		const result = await App.game.startTheGame.call(num_content, rand, App.account,{value: num_content*1000000000000000000,gas:3000000});
		await App.game.startTheGame(num_content, rand, App.account,{value: num_content*1000000000000000000,gas:3000000});
		console.log("result "+result)
		
		if (result ==false){ //game faild for some reason, maybe someone tryed to cheat..
			document.getElementById("starting").innerHTML ="game's faild!, you can try again"
		}
		
		//waiting for the server to calculate, and find out if we have won
		else{
			for (let i = 0; i < 60; i++) {
				finished = !(await App.game.canWeStart())
				//console.log(await App.game.canWeStart())
				if (finished){
					break;
				}
				document.getElementById("starting").innerHTML ="game is loading.. "+ i
				await sleep(1000)
			}
			//update the website if we won or lost
			const we_won = await App.game.amITheLastWinner(App.account)
			console.log("rr"+we_won)
			if (we_won==1){
				document.getElementById("starting").innerHTML ="you won!, you can try again"
			}
			if (we_won==0){
				document.getElementById("starting").innerHTML ="you lost... , you can try again"
			}
			if (we_won==2){
				document.getElementById("starting").innerHTML ="it's a tie!! , you can try again"
			}
		}

	}
	//refresh the game.
	App.setLoading(false)
	await App.render()

  },


  setLoading: (boolean) => {
    App.loading = boolean
    const loader = $('#loader')
    const content = $('#content')
    if (boolean) {
      loader.show()
      content.hide()
    } else {
      loader.hide()
      content.show()
    }
  }
}

$(() => {
  $(window).load(() => {
    App.load()
  })
})