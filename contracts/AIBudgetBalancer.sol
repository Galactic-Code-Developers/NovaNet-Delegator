// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AITreasuryBrain.sol";

contract AIBudgetBalancer is Ownable {
    AITreasuryBrain public treasuryBrain;
    uint256 public reserveThreshold; // Minimum % of treasury to keep in reserves

    event BudgetBalanced(uint256 adjustedSpendingLimit, uint256 reservePercentage);

    constructor(address _treasuryBrain, uint256 _reserveThreshold) {
        treasuryBrain = AITreasuryBrain(_treasuryBrain);
        reserveThreshold = _reserveThreshold;
    }

    function balanceBudget(uint256 proposedSpending) external onlyOwner returns (uint256) {
        (uint256 revenue, uint256 expenses, ) = treasuryBrain.getLatestTreasuryData();
        uint256 availableFunds = revenue - expenses;
        uint256 reservedFunds = (availableFunds * reserveThreshold) / 100;
        uint256 adjustedSpending = availableFunds > reservedFunds ? availableFunds - reservedFunds : 0;

        emit BudgetBalanced(adjustedSpending, reserveThreshold);
        return adjustedSpending;
    }

    function updateReserveThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold <= 50, "Reserve threshold cannot exceed 50%");
        reserveThreshold = newThreshold;
    }
}
