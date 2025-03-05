// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./AIVotingModel.sol";
import "./AIAuditLogger.sol";
import "./AISlashingMonitor.sol";
import "./AISlashingAppeal.sol";
import "./Treasury.sol";

contract DelegatorGovernance is Ownable {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startTime;
        uint256 endTime;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voted;
    }

    enum ProposalType { GENERAL, SLASH_VALIDATOR, TREASURY_ALLOCATION, NETWORK_UPGRADE }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;

    AIVotingModel public votingModel;
    AIAuditLogger public auditLogger;
    AISlashingMonitor public slashingMonitor;
    AISlashingAppeal public slashingAppeal;
    Treasury public treasury;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description);
    event VoteCasted(uint256 indexed id, address indexed voter, bool support, uint256 votingPower);
    event ProposalExecuted(uint256 indexed id);
    event DelegatorSlashed(address indexed delegator, uint256 penalty);

    constructor(
        address _votingModel,
        address _auditLogger,
        address _slashingMonitor,
        address _slashingAppeal,
        address _treasury
    ) {
        votingModel = AIVotingModel(_votingModel);
        auditLogger = AIAuditLogger(_auditLogger);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        slashingAppeal = AISlashingAppeal(_slashingAppeal);
        treasury = Treasury(_treasury);
    }

    /// @notice Submits a new governance proposal
    function submitProposal(string memory _description, uint256 _duration, ProposalType _type) external {
        require(votingPower[msg.sender] > 0, "Insufficient voting power.");

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;
        newProposal.endTime = block.timestamp + _duration;
        newProposal.executed = false;

        auditLogger.logAudit(proposalCount, "PROPOSAL_SUBMITTED", 0, msg.sender);
        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    /// @notice Delegators vote on a governance proposal
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started.");
        require(block.timestamp <= proposal.endTime, "Voting ended.");
        require(!proposal.voted[msg.sender], "Already voted.");

        uint256 voterPower = votingModel.calculateVotingPower(msg.sender);
        require(voterPower > 0, "No voting power.");

        proposal.voted[msg.sender] = true;
        if (_support) {
            proposal.votesFor += voterPower;
        } else {
            proposal.votesAgainst += voterPower;
        }

        auditLogger.logAudit(_proposalId, "VOTE_CASTED", voterPower, msg.sender);
        emit VoteCasted(_proposalId, msg.sender, _support, voterPower);
    }

    /// @notice Executes a passed governance proposal
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Already executed.");
        require(block.timestamp > proposal.endTime, "Voting not ended.");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not approved.");

        proposal.executed = true;

        if (proposal.votesFor < 1000 ether) {
            slashingMonitor.flagSuspiciousVoting(proposal.proposer);
        }

        auditLogger.logAudit(_proposalId, "PROPOSAL_EXECUTED", 0, msg.sender);
        emit ProposalExecuted(_proposalId);
    }

    /// @notice Slashes delegators for fraudulent governance actions
    function applyDelegatorSlashing(address delegator, uint256 penalty) external onlyOwner {
        require(votingPower[delegator] > 0, "Delegator has no stake.");

        uint256 slashAmount = (votingPower[delegator] * penalty) / 100;
        votingPower[delegator] -= slashAmount;

        slashingMonitor.trackSlashingEvent(delegator, slashAmount);
        treasury.receiveSlashedFunds(delegator, slashAmount);
        auditLogger.logAudit(0, "DELEGATOR_SLASHED", slashAmount, delegator);

        emit DelegatorSlashed(delegator, slashAmount);
    }

    /// @notice Allows delegators to appeal slashing decisions
    function appealSlashing(uint256 caseId) external {
        require(votingPower[msg.sender] > 0, "No voting power.");

        bool appealSuccess = slashingAppeal.processAppeal(msg.sender, caseId);
        if (appealSuccess) {
            emit DelegatorSlashed(msg.sender, 0);
        }
    }

    /// @notice Gets the voting power of a delegator
    function getVotingPower(address delegator) external view returns (uint256) {
        return votingModel.calculateVotingPower(delegator);
    }

    /// @notice Retrieves proposal details
    function getProposal(uint256 _proposalId) external view returns (
        address proposer, 
        string memory description, 
        uint256 votesFor, 
        uint256 votesAgainst, 
        bool executed
    ) {
        Proposal storage proposal = proposals[_proposalId];
        return (proposal.proposer, proposal.description, proposal.votesFor, proposal.votesAgainst, proposal.executed);
    }
}
