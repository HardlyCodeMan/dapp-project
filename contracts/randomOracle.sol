// SPDX-License-Identifier: GPL3
pragma solidity 0.5.12;

import "./provableAPI.sol";

contract randomOracle is usingProvable {
    uint256 constant NUM_RANDOM_BYTES_REQUESTED = 1; // Using 1 byte we can use nums 0-255
    uint256 public latestNumber;

    event LogNewProvableQuery(string description);
    event generateRandomNumber(uint256 randomNumber);

    constructor() public {
        update();
    }

    function __callback(bytes32 _queryId, string memory _result, bytes memory _proof) public {
        require(msg.sender == provable_cbAddress());

        uint randomNumber = uint256(keccak256(abi.encodePacked(_result))) % 100;
        latestNumber = randomNumber;
        
        emit generateRandomNumber(randomNumber);
    }

    // called to initiate a new random number between 0 and 255
    function update() payable public {
        uint256 QUERY_EXECUTION_DELAY = 0;
        uint256 GAS_FOR_CALLBACK = 200000;
        bytes32 queryId = provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        );

        emit LogNewProvableQuery("Provable query sent, awaiting response");
    }

    // For local testing purposes
    // testRandom for local  ganache testing of the framework without needing to wait for confirmations
    // on the testnet to check fucntions and test contract
    function testRandom() public returns (bytes32) {
        bytes32 queryId = bytes32(keccak256(abi.encodePacked(msg.sender)));

        __callback(queryId, "test", bytes("test")); // inject test data response
        return queryId;
    }
}