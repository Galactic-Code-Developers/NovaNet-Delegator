// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIGovernanceFraudDetection is Ownable {
    mapping(address => bool) public flaggedVoters;

    event VoterFlagged(address indexed voter, string reason);
    event VoterCleared(address indexed voter);

    function flagVoter(address voter, string memory reason) external onlyOwner {
        flaggedVoters[voter] = true;
        emit VoterFlagged(voter, reason);
    }

    function clearVoter(address voter) external onlyOwner {
        flaggedVoters[voter] = false;
        emit VoterCleared(voter);
    }

    function isVoterFlagged(address voter) external view returns (bool) {
        return flaggedVoters[voter];
    }
}
