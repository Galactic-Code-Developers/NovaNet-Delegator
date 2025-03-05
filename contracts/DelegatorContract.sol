// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./AIValidatorSelection.sol";
import "./AIRewardDistribution.sol";
import "./AISlashingMonitor.sol";
import "./AISlashingAppeal.sol";
import "./AIVotingModel.sol";
import "./Treasury.sol";

contract DelegatorContract is Ownable {
    struct Delegation {
        address delegator;
        address validator;
        uint256 amount;
        uint256 lastRewardClaim;
    }

    NovaNetValidator public validatorContract;
    AIValidatorSelection public aiValidatorSelection;
    AIRewardDistribution public aiRewardDistribution;
    AISlashingMonitor public slashingMonitor;
    AISlashingAppeal public slashingAppeal;
    AIVotingModel public votingModel;
    Treasury public treasury;

    mapping(address => Delegation) public delegations;
    mapping(address => uint256) public totalStakedByDelegator;

    event StakeDelegated(address indexed delegator, address indexed validator, uint256 amount);
    event StakeWithdrawn(address indexed delegator, uint256 amount);
    event RewardsClaimed(address indexed delegator, uint256 amount);
    event DelegatorSlashed(address indexed delegator, uint256 penalty);
    event DelegationReassigned(address indexed delegator, address indexed newValidator, uint256 amount);

    constructor(
        address _validatorContract,
        address _aiValidatorSelection,
        address _aiRewardDistribution,
        address _slashingMonitor,
        address _slashingAppeal,
        address _votingModel,
        address _treasury
    ) {
        validatorContract = NovaNetValidator(_validatorContract);
        aiValidatorSelection = AIValidatorSelection(_aiValidatorSelection);
        aiRewardDistribution = AIRewardDistribution(_aiRewardDistribution);
        slashingMonitor = AISlashingMonitor(_slashingMonitor);
        slashingAppeal = AISlashingAppeal(_slashingAppeal);
        votingModel = AIVotingModel(_votingModel);
        treasury = Treasury(_treasury);
    }

    /// @notice Delegate stake to an AI-selected validator
    function delegateStake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens.");
        require(delegations[msg.sender].validator == address(0), "Already staked.");

        address bestValidator = aiValidatorSelection.selectBestValidator();
        require(bestValidator != address(0), "No suitable validators found.");

        delegations[msg.sender] = Delegation(msg.sender, bestValidator, amount, block.timestamp);
        totalStakedByDelegator[msg.sender] += amount;
        validatorContract.stake(msg.sender, bestValidator, amount);

        emit StakeDelegated(msg.sender, bestValidator, amount);
    }

    /// @notice Withdraw staked funds
    function withdrawStake() external {
        require(delegations[msg.sender].amount > 0, "No stake found.");

        uint256 amount = delegations[msg.sender].amount;
        address validator = delegations[msg.sender].validator;

        validatorContract.unstake(msg.sender, validator, amount);
        delete delegations[msg.sender];
        totalStakedByDelegator[msg.sender] -= amount;

        emit StakeWithdrawn(msg.sender, amount);
    }

    /// @notice Allows delegators to reassign their delegation to a different validator
    function reassignDelegation() external {
        require(delegations[msg.sender].amount > 0, "No active delegation.");

        uint256 amount = delegations[msg.sender].amount;
        address newValidator = aiValidatorSelection.selectBestValidator();
        require(newValidator != address(0) && newValidator != delegations[msg.sender].validator, "No better validator available.");

        // Unstake from old validator and reassign to new one
        validatorContract.unstake(msg.sender, delegations[msg.sender].validator, amount);
        validatorContract.stake(msg.sender, newValidator, amount);

        delegations[msg.sender].validator = newValidator;
        emit DelegationReassigned(msg.sender, newValidator, amount);
    }

    /// @notice Claim staking rewards
    function claimRewards() external {
        require(delegations[msg.sender].amount > 0, "No active delegation.");

        uint256 rewards = aiRewardDistribution.calculateRewards(msg.sender);
        delegations[msg.sender].lastRewardClaim = block.timestamp;

        aiRewardDistribution.distributeRewards(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Handles AI-driven slashing for delegators
    function applyDelegatorSlashing(address delegator, uint256 penalty) external onlyOwner {
        require(delegations[delegator].amount > 0, "Delegator not found.");

        uint256 slashAmount = (delegations[delegator].amount * penalty) / 100;
        delegations[delegator].amount -= slashAmount;
        totalStakedByDelegator[delegator] -= slashAmount;

        slashingMonitor.trackSlashingEvent(delegator, slashAmount);
        emit DelegatorSlashed(delegator, slashAmount);
    }

    /// @notice Allows delegators to appeal slashing decisions using AI-based review
    function appealSlashing(uint256 caseId) external {
        require(delegations[msg.sender].amount > 0, "No delegation found.");
        bool appealSuccess = slashingAppeal.processAppeal(msg.sender, caseId);

        if (appealSuccess) {
            emit DelegatorSlashed(msg.sender, 0);
        }
    }

    /// @notice Gets the voting power of a delegator
    function getVotingPower(address delegator) external view returns (uint256) {
        return votingModel.calculateVotingPower(delegator);
    }

    /// @notice Gets total staked by delegator
    function getTotalStaked(address delegator) external view returns (uint256) {
        return totalStakedByDelegator[delegator];
    }
}
