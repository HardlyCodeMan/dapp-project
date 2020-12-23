var web3 = new Web3(Web3.givenProvider);
var contractInstance;

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts) {
        contractInstance = new web3.eth.Contract(abi, "0xA298622F83f7781f565B39b1BFb97344D67E2251", {from: accounts[0]});
        console.log(contractInstance);
    });
    $("#heads_button").click(newFlip(0));
    $("#tails_button").click(newFlip(1));
    $("#results_button").click(fetchAndDisplay);
});

function newFlip(_expectedInt) {
    // Form inputs
    var _value = $("#value_input").val();
    var _expected;

    if(_expectedInt = 0) {
        _expected = "Heads";
    } else {
        _expected = "Tails";
    }
    
    // Metamask signing params
    var sendConfig = {
        value: web3.utils.toWei(_value, "ether")
    };

    // Let Metamask send the transaction
    contractInstance.methods.newCoinFlip(_expected, _expectedInt).send(sendConfig)
        // Gett the tx hash
        .on("transactionHash", function(hash) {
            console.log("Tx Hash: " + hash);
        })
        // Get tx confirmations, min 12 recommended for mainnet
        .on("confirmation", function(confirmationNr) {
            console.log("Confirmations: " + confirmationNr);
        })
        // Get tx receipt, outcome & state changes of the tx
        .on("receipt", function(receipt) {
            console.log("Receipt: " + JSON.stringify(receipt));
        })
}

function fetchAndDisplay() {
    // Get the data from the blockchain
    contractInstance.methods.getPerson().call().then(function(result) {
        console.log(result);

        // Set the HTML elements
        $("#name_output").text(result.name);
        $("#age_output").text(result.age);
        $("#height_output").text(result.height);
    })
}
    