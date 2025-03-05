// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NovaNetValidator.sol";

contract AIVotingModel {
    NovaNetValidator public validatorContract;
    mapping(address => uint256) public votingPower;

    event VotingPowerAdjusted(address indexed voter, uint256 newPower);

    constructor(address _validatorContract) {
        validatorContract = NovaNetValidator(_validatorContract);
    }

    function calculateVotingPower(address _voter) external {
        uint256 stake = validatorContract.getValidatorStake(_voter);
        uint256 reputation = validatorContract.getValidatorReputation(_voter);
        
        uint256 adjustedPower = (stake * 70 / 100) + (reputation * 30 / 100);
        votingPower[_voter] = adjustedPower;

        emit VotingPowerAdjusted(_voter, adjustedPower);
    }

    function getVotingPower(address _voter) external view returns (uint256) {
        return votingPower[_voter];
    }
}
