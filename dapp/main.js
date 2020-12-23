var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts) {
        contractInstance = new web3.eth.Contract(abi, "0x841372142eC7CfB0d490021BAC67d6AE3719d1E4", {from: accounts[0]});
        console.log(contractInstance);
    });
    $("#heads_button").click(flipHeads);
    $("#tails_button").click(flipTails);
    //$("#results_button").click(fetchAndDisplay);
});

//
// Receive jQuery error when attempting to combine the 2 flip functions into 1 and pass an int to define heads or tails
//

function flipHeads() {
    // Form inputs
    var _value = $("#value_input").val();
    var _expected = "Heads";
    var _expectedInt = 0;
    
    // Metamask signing params
    var sendConfig = {
        value: web3.utils.toWei(_value, "ether")
    };

    // Let Metamask send the transaction
    contractInstance.methods.newCoinFlip(_expected, _expectedInt).send(sendConfig)
        // Gett the tx hash
        .on("transactionHash", function(hash) {
            //console.log("Tx Hash: " + hash);
        })
        // Get tx confirmations, min 12 recommended for mainnet
        .on("confirmation", function(confirmationNr) {
            //console.log("Confirmations: " + confirmationNr);
        })
        // Get tx receipt, outcome & state changes of the tx
        .on("receipt", function(receipt) {
            //console.log("Receipt: " + JSON.stringify(receipt.events.newFlipResultEvent.returnValues._win));
            flip = receipt.events.newFlipEvent.returnValues;
            result = receipt.events.newFlipResultEvent.returnValues;
            resultDisplay(flip, result);
        })
}

function flipTails() {
    // Form inputs
    var _value = $("#value_input").val();
    var _expected = "Heads";
    var _expectedInt = 0;
    
    // Metamask signing params
    var sendConfig = {
        value: web3.utils.toWei(_value, "ether")
    };

    // Let Metamask send the transaction
    contractInstance.methods.newCoinFlip(_expected, _expectedInt).send(sendConfig)
        // Gett the tx hash
        .on("transactionHash", function(hash) {
            //console.log("Tx Hash: " + hash);
        })
        // Get tx confirmations, min 12 recommended for mainnet
        .on("confirmation", function(confirmationNr) {
            //console.log("Confirmations: " + confirmationNr);
        })
        // Get tx receipt, outcome & state changes of the tx
        .on("receipt", function(receipt) {
            //console.log("Receipt: " + JSON.stringify(receipt.events.newFlipResultEvent.returnValues._win));
            flip = receipt.events.newFlipEvent.returnValues;
            result = receipt.events.newFlipResultEvent.returnValues;
            resultDisplay(flip, result);
        })
}

function resultDisplay(flip, result) {
    // Get balance from the blockchain
    contractInstance.methods.getbalance().call.then(function(balance) {

        $("#id_output").text(flip._id);
        $("#choice_output").text(flip._expected);
        $("#wager_output").text(web3.utils.fromWei(flip._value));
        $("#flip_output").text(result._result);
        $("#result_output").text(result._win);
        $("#wager_output").text(web3.utils.fromWei(balance));
    })
}