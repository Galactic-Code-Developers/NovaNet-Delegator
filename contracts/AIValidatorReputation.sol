// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NovaNetValidator.sol";

contract AIValidatorReputation {
    struct ValidatorPerformance {
        uint256 uptime;
        uint256 blockValidationCount;
        uint256 securityScore;
        uint256 stakeAmount;
        uint256 reputationScore;
    }

    mapping(address => ValidatorPerformance) public validatorScores;
    NovaNetValidator public validatorContract;

    event ReputationUpdated(address indexed validator, uint256 reputationScore);

    constructor(address _validatorContract) {
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function updateReputation(
        address _validator,
        uint256 _uptime,
        uint256 _blockCount,
        uint256 _securityScore
    ) external {
        require(validatorContract.isValidator(_validator), "Not a validator");

        uint256 stakeWeight = validatorContract.getValidatorStake(_validator) / 1e18;
        uint256 repScore = (_uptime * 40 / 100) + (_blockCount * 30 / 100) + (_securityScore * 20 / 100) + (stakeWeight * 10 / 100);
        
        validatorScores[_validator] = ValidatorPerformance(_uptime, _blockCount, _securityScore, stakeWeight, repScore);

        emit ReputationUpdated(_validator, repScore);
    }

    function getReputationScore(address _validator) external view returns (uint256) {
        return validatorScores[_validator].reputationScore;
    }
}
