// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIFraudDetection is Ownable {
    mapping(address => bool) public flaggedDelegators;

    event DelegatorFlagged(address indexed delegator, string reason);
    event DelegatorCleared(address indexed delegator);

    function flagDelegator(address delegator, string memory reason) external onlyOwner {
        flaggedDelegators[delegator] = true;
        emit DelegatorFlagged(delegator, reason);
    }

    function clearDelegator(address delegator) external onlyOwner {
        flaggedDelegators[delegator] = false;
        emit DelegatorCleared(delegator);
    }

    function isDelegatorFlagged(address delegator) external view returns (bool) {
        return flaggedDelegators[delegator];
    }
}
