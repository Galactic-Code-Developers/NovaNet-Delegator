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

contract DelegatorStaking is Ownable {
    struct StakingInfo {
        address delegator;
        address validator;
        uint256 amount;
        uint256 stakingTime;
        uint256 lastClaimTime;
    }

    NovaNetValidator public validatorContract;
    AIValidatorSelection public aiValidatorSelection;
    AIRewardDistribution public aiRewardDistribution;
    AISlashingMonitor public slashingMonitor;
    AISlashingAppeal public slashingAppeal;
    AIVotingModel public votingModel;
    Treasury public treasury;

    mapping(address => StakingInfo) public stakingRecords;
    mapping(address => uint256) public totalStakedByDelegator;

    event StakePlaced(address indexed delegator, address indexed validator, uint256 amount, uint256 stakingTime);
    event StakeWithdrawn(address indexed delegator, uint256 amount);
    event RewardsClaimed(address indexed delegator, uint256 amount);
    event DelegatorSlashed(address indexed delegator, uint256 penalty);
    event DelegationUpdated(address indexed delegator, address indexed newValidator, uint256 amount);

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

    /// @notice Stake tokens with AI-recommended validator
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0 tokens.");
        require(stakingRecords[msg.sender].validator == address(0), "Already staked.");

        address bestValidator = aiValidatorSelection.selectBestValidator();
        require(bestValidator != address(0), "No suitable validators available.");

        stakingRecords[msg.sender] = StakingInfo(msg.sender, bestValidator, amount, block.timestamp, block.timestamp);
        totalStakedByDelegator[msg.sender] += amount;
        validatorContract.stake(msg.sender, bestValidator, amount);

        emit StakePlaced(msg.sender, bestValidator, amount, block.timestamp);
    }

    /// @notice Withdraw staked funds
    function withdrawStake() external {
        require(stakingRecords[msg.sender].amount > 0, "No stake found.");

        uint256 amount = stakingRecords[msg.sender].amount;
        address validator = stakingRecords[msg.sender].validator;

        validatorContract.unstake(msg.sender, validator, amount);
        delete stakingRecords[msg.sender];
        totalStakedByDelegator[msg.sender] -= amount;

        emit StakeWithdrawn(msg.sender, amount);
    }

    /// @notice Allows delegators to switch their validator without unstaking
    function reassignValidator() external {
        require(stakingRecords[msg.sender].amount > 0, "No active stake.");

        uint256 amount = stakingRecords[msg.sender].amount;
        address newValidator = aiValidatorSelection.selectBestValidator();
        require(newValidator != address(0) && newValidator != stakingRecords[msg.sender].validator, "No better validator available.");

        validatorContract.unstake(msg.sender, stakingRecords[msg.sender].validator, amount);
        validatorContract.stake(msg.sender, newValidator, amount);

        stakingRecords[msg.sender].validator = newValidator;
        emit DelegationUpdated(msg.sender, newValidator, amount);
    }

    /// @notice Claim staking rewards
    function claimRewards() external {
        require(stakingRecords[msg.sender].amount > 0, "No active staking.");

        uint256 rewards = aiRewardDistribution.calculateRewards(msg.sender);
        stakingRecords[msg.sender].lastClaimTime = block.timestamp;

        aiRewardDistribution.distributeRewards(msg.sender, rewards);
        emit RewardsClaimed(msg.sender, rewards);
    }

    /// @notice Handles AI-driven slashing for delegators
    function applyDelegatorSlashing(address delegator, uint256 penalty) external onlyOwner {
        require(stakingRecords[delegator].amount > 0, "Delegator not found.");

        uint256 slashAmount = (stakingRecords[delegator].amount * penalty) / 100;
        stakingRecords[delegator].amount -= slashAmount;
        totalStakedByDelegator[delegator] -= slashAmount;

        slashingMonitor.trackSlashingEvent(delegator, slashAmount);
        emit DelegatorSlashed(delegator, slashAmount);
    }

    /// @notice Allows delegators to appeal slashing decisions via AI
    function appealSlashing(uint256 caseId) external {
        require(stakingRecords[msg.sender].amount > 0, "No delegation found.");
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
