// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIDelegatorNotifier is Ownable {
    event NotificationSent(address indexed delegator, string message);

    function sendNotification(address delegator, string memory message) external onlyOwner {
        emit NotificationSent(delegator, message);
    }
}
