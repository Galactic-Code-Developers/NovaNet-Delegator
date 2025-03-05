// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AITreasuryAdjuster is Ownable {
    uint256 public baseContributionRate = 5; // Default 5%
    
    event ContributionRateUpdated(uint256 newRate);

    function adjustTreasuryContribution(uint256 newRate) external onlyOwner {
        require(newRate >= 2 && newRate <= 10, "Rate must be between 2% and 10%");
        baseContributionRate = newRate;
        emit ContributionRateUpdated(newRate);
    }

    function getTreasuryContribution() external view returns (uint256) {
        return baseContributionRate;
    }
}
