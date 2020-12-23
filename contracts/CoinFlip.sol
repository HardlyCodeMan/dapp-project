// SPDX-License-Identifier: GPL3
pragma solidity 0.5.12;

import "./Ownable.sol";

/* /// Basic randomness hint code
contract RandomTest{
    function random() public view returns (uint) {
        // blocktimestamp (now()) modulus by 2 returing the remainder (0 or 1)
        // NOT RANDOM, only appears to be random
        return now %2; 
    }
}
*/
contract CoinFlip is Ownable {

    struct Flip {
        uint id;
        address player;
        string expected;
        uint expectedInt;
        string result;
        uint resultInt;
        uint value;
        bool win;
    }

    Flip[] public completedFlips;

    mapping (address => uint) addressBalance;
    //mapping (address => Flip) private flippers;
    //mapping (address => completedFlips[]);

    event newDepositEvent(address _address, uint _value);
    event newWithdrawlEvent(address _to, address _from, uint _value);
    event eventWithdrawAll(uint _value);
    event newFlipEvent(uint _id, address _user, string _expected, uint _expectedInt, uint _value);
    event newFlipResultEvent(uint _id, address _user, string _result, uint _resultInt, bool _win, uint _value);

    modifier costs(uint cost) {
        require (msg.value >= cost);
        _;
    }

    function newCoinFlip(string memory _expected, uint _expectedInt) public payable {        
        require(msg.value > 0, "Must place a wager.");
        addressBalance[msg.sender] += msg.value;

        uint _id = completedFlips.length;
        address _user = msg.sender;
        string memory _result;
        uint _resultInt;
        uint _value = msg.value;
        bool _win;
        uint _winnings;

        uint _randomFlip = randomFlip(_id, _user, _expected, _expectedInt, _value);
        require(_randomFlip == 0 || _randomFlip == 1, "Flip randomness error.");

        if(_randomFlip == 0) {
            _result = "Heads";
            _resultInt = _randomFlip;
        } else {
            _result = "Tails";
            _resultInt = _randomFlip;
        }

        if(_expectedInt == _resultInt) {
            _win = true;
            processWin(_value);
            _winnings = 2 * _value;
        } else {
            _win = false;
            processLoss(_value);
            _winnings = 0;
        }

        Flip memory newFlip;
        newFlip.id = _id;
        newFlip.player = _user;
        newFlip.expected = _expected;
        newFlip.expectedInt = _expectedInt;
        newFlip.result = _result;
        newFlip.resultInt = _resultInt;
        newFlip.value = _value;
        newFlip.win = _win;

        completedFlips.push(newFlip);

        emit newFlipResultEvent(_id, _user, _result, _resultInt, _win, _winnings);
    }

    function randomFlip(uint _id, address _user, string memory _expected, uint _expectedInt, uint _value) public returns (uint) {
        // blocktimestamp (now()) modulus by 2 returing the remainder (0 or 1)
        // NOT RANDOM, only appears to be random
        uint rand = now % 2;
        
        emit newFlipEvent(_id, _user, _expected, _expectedInt, _value);

        return rand;
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