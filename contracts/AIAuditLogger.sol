// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIAuditLogger is Ownable {
    struct AuditLog {
        uint256 proposalId;
        uint256 timestamp;
        string actionType;
        uint256 amount;
        address executor;
    }

    mapping(uint256 => AuditLog) public auditLogs; // Stores logs by proposal ID
    uint256 public logCount;

    event AuditLogged(uint256 indexed proposalId, uint256 timestamp, string actionType, uint256 amount, address indexed executor);

    /// @notice Logs governance actions with AI tracking
    /// @param proposalId The unique ID of the proposal being logged
    /// @param actionType The type of action performed (e.g., "PROPOSAL_EXECUTED", "TREASURY_ALLOCATION")
    /// @param amount The relevant amount affected (e.g., fund allocation)
    /// @param executor The address that performed the action
    function logAudit(uint256 proposalId, string memory actionType, uint256 amount, address executor) external onlyOwner {
        logCount++;
        auditLogs[proposalId] = AuditLog(proposalId, block.timestamp, actionType, amount, executor);
        emit AuditLogged(proposalId, block.timestamp, actionType, amount, executor);
    }

    /// @notice Retrieves an audit log by proposal ID
    /// @param proposalId The ID of the proposal to retrieve logs for
    /// @return AuditLog struct containing audit details
    function getAuditLogByProposalId(uint256 proposalId) external view returns (AuditLog memory) {
        return auditLogs[proposalId];
    }
}
