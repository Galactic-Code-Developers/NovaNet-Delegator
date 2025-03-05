// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./AISlashingMonitor.sol";
import "./AISlashingAppeal.sol";
import "./AIAuditLogger.sol";
import "./Treasury.sol";

contract DelegatorSlashing is Ownable {
    NovaNetValidator public validatorContract;
    AISlashingMonitor public slashingMonitor;
    AISlashingAppeal public slashingAppeal;
    AIAuditLogger public auditLogger;
    Treasury public treasury;

    struct SlashingRecord {
        address delegator;
        uint256 penalty;
        uint256 timestamp;
        bool appealed;
        bool successfulAppeal;
    }

    mapping(address => SlashingRecord[]) public slashingHistory;
    mapping(address => uint256) public totalSlashedByDelegator;

    event DelegatorSlashed(address indexed delegator, uint256 penalty);
    event SlashingAppealed(address indexed delegator, uint256 caseId, bool successful);

    constructor(
        address _validatorContract,
        address _slashingMonitor,
        address _slashingAppeal,
        address _auditLogger,
        address _treasury
    ) {
        validatorContract = NovaNetValidator(_validatorContract);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        slashingAppeal = AISlashingAppeal(_slashingAppeal);
        auditLogger = AIAuditLogger(_auditLogger);
        treasury = Treasury(_treasury);
    }

    /// @notice Applies a slashing penalty to a delegator
    /// @param delegator Address of the delegator being penalized
    /// @param penalty Percentage of stake to be slashed (e.g., 5 for 5%)
    function applySlashing(address delegator, uint256 penalty) external onlyOwner {
        require(validatorContract.getDelegatedStake(delegator) > 0, "No delegation found.");
        require(penalty > 0 && penalty <= 100, "Invalid penalty percentage.");

        uint256 stakeAmount = validatorContract.getDelegatedStake(delegator);
        uint256 slashAmount = (stakeAmount * penalty) / 100;

        // Update delegator's total slashed amount
        totalSlashedByDelegator[delegator] += slashAmount;

        // Store slashing event
        slashingHistory[delegator].push(SlashingRecord(delegator, slashAmount, block.timestamp, false, false));

        // Deduct stake and send funds to treasury
        validatorContract.reduceDelegation(delegator, slashAmount);
        treasury.receiveSlashedFunds(delegator, slashAmount);

        // Log slashing action in AI audit logs
        auditLogger.logAudit(
            0, // Proposal ID (not applicable here)
            "DELEGATOR_SLASHED",
            slashAmount,
            delegator
        );

        emit DelegatorSlashed(delegator, slashAmount);
    }

    /// @notice Allows delegators to appeal a slashing decision using AI validation
    /// @param caseId ID of the slashing case in history
    function appealSlashing(uint256 caseId) external {
        require(slashingHistory[msg.sender].length > caseId, "Invalid case ID.");
        require(!slashingHistory[msg.sender][caseId].appealed, "Already appealed.");

        bool appealSuccess = slashingAppeal.processAppeal(msg.sender, caseId);
        slashingHistory[msg.sender][caseId].appealed = true;
        slashingHistory[msg.sender][caseId].successfulAppeal = appealSuccess;

        if (appealSuccess) {
            uint256 refundAmount = slashingHistory[msg.sender][caseId].penalty;
            treasury.refundSlashedFunds(msg.sender, refundAmount);
        }

        emit SlashingAppealed(msg.sender, caseId, appealSuccess);
    }

    /// @notice Gets total amount slashed from a delegator
    /// @param delegator Address of the delegator
    /// @return Total slashed amount
    function getTotalSlashed(address delegator) external view returns (uint256) {
        return totalSlashedByDelegator[delegator];
    }

    /// @notice Retrieves all slashing records for a delegator
    /// @param delegator Address of the delegator
    /// @return Array of slashing records
    function getSlashingHistory(address delegator) external view returns (SlashingRecord[] memory) {
        return slashingHistory[delegator];
    }
}
