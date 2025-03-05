// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AITreasurySimulator.sol";
import "./AIBudgetOptimizer.sol";
import "./AIReserveManager.sol";
import "./AIAuditLogger.sol";

contract Treasury is Ownable {
    AITreasurySimulator public treasurySimulator;
    AIBudgetOptimizer public budgetOptimizer;
    AIReserveManager public reserveManager;
    AIAuditLogger public auditLogger;

    uint256 public totalFunds;
    mapping(address => uint256) public allocatedFunds;

    event FundsAllocated(address indexed recipient, uint256 amount, uint256 aiApprovalScore);
    event FundsWithdrawn(address indexed recipient, uint256 amount);
    event TreasuryUpdated(uint256 newTotalFunds, uint256 aiReserveThreshold);

    constructor(
        address _treasurySimulator,
        address _budgetOptimizer,
        address _reserveManager,
        address _auditLogger
    ) {
        treasurySimulator = AITreasurySimulator(_treasurySimulator);
        budgetOptimizer = AIBudgetOptimizer(_budgetOptimizer);
        reserveManager = AIReserveManager(_reserveManager);
        auditLogger = AIAuditLogger(_auditLogger);
    }

    /// @notice Function to deposit funds into the treasury
    function depositFunds() external payable onlyOwner {
        totalFunds += msg.value;
        uint256 reserveThreshold = reserveManager.updateReserveThreshold(totalFunds);
        emit TreasuryUpdated(totalFunds, reserveThreshold);
    }

    /// @notice Function to allocate funds based on AI approval and treasury stability
    function allocateFunds(address payable recipient, uint256 amount) external onlyOwner {
        require(totalFunds >= amount, "Insufficient treasury balance");

        // AI-powered allocation scoring and budget validation
        uint256 aiApprovalScore = treasurySimulator.analyzeFundRequest(recipient, amount);
        require(aiApprovalScore > 50, "AI rejected fund request due to risk analysis");

        uint256 optimizedAmount = budgetOptimizer.optimizeAllocation(amount, aiApprovalScore);
        require(totalFunds >= optimizedAmount, "Budget constraints exceeded");

        // Ensure treasury stability using AI reserve management
        bool reserveCheck = reserveManager.verifyStability(totalFunds, optimizedAmount);
        require(reserveCheck, "AI Reserve Manager: Allocation may destabilize treasury");

        totalFunds -= optimizedAmount;
        allocatedFunds[recipient] += optimizedAmount;
        recipient.transfer(optimizedAmount);

        // Log AI allocation decision
        auditLogger.logAllocation(recipient, optimizedAmount, aiApprovalScore);

        emit FundsAllocated(recipient, optimizedAmount, aiApprovalScore);
    }

    /// @notice Function to withdraw allocated funds
    function withdrawFunds(uint256 amount) external {
        require(allocatedFunds[msg.sender] >= amount, "Insufficient allocated funds");

        allocatedFunds[msg.sender] -= amount;
        totalFunds -= amount;
        payable(msg.sender).transfer(amount);

        auditLogger.logWithdrawal(msg.sender, amount);
        emit FundsWithdrawn(msg.sender, amount);
    }

    /// @notice Function to get treasury balance
    function getTreasuryBalance() external view returns (uint256) {
        return totalFunds;
    }

    /// @notice Function to simulate treasury growth over time
    function simulateTreasuryGrowth(uint256 months) external view returns (uint256 projectedBalance) {
        return treasurySimulator.simulateGrowth(totalFunds, months);
    }
}
