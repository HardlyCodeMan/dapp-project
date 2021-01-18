// SPDX-License-Identifier: GPL3
pragma solidity 0.5.12;

import "./Ownable.sol";
import "./provableAPI.sol";

/* /// Basic randomness hint code
contract RandomTest{
    function random() public view returns (uint) {
        // blocktimestamp (now()) modulus by 2 returing the remainder (0 or 1)
        // NOT RANDOM, only appears to be random
        return now %2; 
    }
}
*/
contract CoinFlip is Ownable, usingProvable {

    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1; // Using 1 byte we can use nums 0-255
    uint256 public latestNumber;

    struct Flip {
        uint id;
        address player;
        bytes32 queryId;
        uint expected;
        uint result;
        uint value;
        bool win;
    }

    Flip[] public Flips;

    mapping (address => uint) public addressBalance;
    //mapping (address => Flip) private flippers;
    //mapping (address => Flips[]);

    event newDepositEvent(address _address, uint _value);
    event newWithdrawlEvent(address _to, address _from, uint _value);
    event eventWithdrawAll(uint _value);
    event newFlipEvent(uint _id, address _user, bytes32 _queryId, uint _expected, uint _value);
    event newFlipResultEvent(uint _id, address _user, uint _result, bool _win, uint _value);
    event LogNewProvableQuery(string description);
    event generateRandomNumber(uint256 randomNumber);

    modifier costs(uint cost) {
        require (msg.value >= cost);
        _;
    }

    constructor() public {
        update();
    }

    function newCoinFlip(uint _expected) public payable {        
        require(msg.value > 0, "Must place a wager.");
        addressBalance[msg.sender] += msg.value;

        uint _id = Flips.length;
        address _user = msg.sender;
        bytes32 _queryId = update();
        uint _value = msg.value;

        Flip memory newFlip;
        newFlip.id = _id;
        newFlip.player = _user;
        newFlip.queryId = _queryId;
        newFlip.expected = _expected;
        newFlip.value = _value;

        Flips.push(newFlip);

        emit newFlipEvent(_id, _user, _queryId, _expected, _value);
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        uint randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 100;
        latestNumber = randomNumber;

        Flips.queryId[_queryId];
        
        emit generateRandomNumber(randomNumber);
    }

    // called to initiate a new random number between 0 and 255
    function update() payable public returns(bytes32) {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        bytes32 queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit LogNewProvableQuery("Provable query sent, awaiting response");

        return queryId;
    }

    // For local testing purposes
    // testRandom for local  ganache testing of the framework without needing to wait for confirmations
    // on the testnet to check fucntions and test contract
    function testRandom() public returns (bytes32) {
        bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));

        __callback(queryId, "test", bytes("test")); // inject test data response
        return queryId;
    }

    function processWin(uint _value) private {
        // transfer funds to msg.sender

        uint tempBalance = addressBalance[msg.sender];
        addressBalance[msg.sender] += _value;

        uint tempContractBalance = addressBalance[address(this)];
        addressBalance[address(this)] -= _value;

        require(addressBalance[msg.sender] == (tempBalance + _value));
        require(addressBalance[address(this)] == (tempContractBalance - _value));

        //withdrawl();
    }

    function processLoss(uint _value) private {
        // msg.sender gets no funds
        uint tempBalance = addressBalance[msg.sender];
        addressBalance[msg.sender] -= _value;

        uint tempContractBalance = addressBalance[address(this)];
        addressBalance[address(this)] += _value;

        require(addressBalance[msg.sender] == (tempBalance - _value));
        require(addressBalance[address(this)] == (tempContractBalance + _value));
    }

    function getBalance() public view returns(uint) {
        if(addressBalance[msg.sender] > 0) {
            return addressBalance[msg.sender];
        } else {
            return 0;
        }
    }

    function getContractBalance() public view onlyOwner returns(uint) {
        if(addressBalance[address(this)] > 0) {
            return addressBalance[address(this)];
        } else {
            return 0;
        }
    }

    function deposit() public payable {
        // User deposit funds
        require(msg.value > 0, "Must place a wager.");
        addressBalance[msg.sender] += msg.value;

        emit newDepositEvent(msg.sender, addressBalance[msg.sender]);
    }


    function withdrawl() private {
        // User removal of funds
        require(addressBalance[msg.sender] > 0, "User has no funds to withdraw");

        uint tempAddressBalance = addressBalance[msg.sender];
        addressBalance[msg.sender] = 0;
        msg.sender.transfer(tempAddressBalance);

        emit newWithdrawlEvent(msg.sender, address(this), tempAddressBalance);
    }

    /* // Not in use
    function _transfer(address _from, address _to, uint _amount) private {
        // transfer between addresses

    }*/

    function withdrawlAll() public onlyOwner {
        uint tempContractBalance = addressBalance[address(this)];
        addressBalance[address(this)] = 0;
        msg.sender.transfer(tempContractBalance);

        emit eventWithdrawAll(tempContractBalance);
    }
}