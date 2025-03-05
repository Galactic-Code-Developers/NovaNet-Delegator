// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AISlashingMonitor.sol";

contract AISlashingAdjuster is Ownable {
    AISlashingMonitor public slashingMonitor;

    constructor(address _slashingMonitor) {
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
    }

    function getAdjustedSlashingPenalty(address delegator, uint256 basePenalty) external view returns (uint256) {
        uint256 violationCount = slashingMonitor.getViolationCount(delegator);
        return basePenalty + (violationCount * 2); // Increase penalty for repeat offenses
    }
}
