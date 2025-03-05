// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorReputation.sol";

contract AIValidatorLeaderboard {
    AIValidatorReputation public reputationContract;

    event LeaderboardUpdated(address indexed validator, uint256 score);

    constructor(address _reputationContract) {
        reputationContract = AIValidatorReputation(_reputationContract);
    }

    function getTopValidators() external view returns (address[] memory) {
        address[] memory validators = reputationContract.getAllValidators();
        address;

        for (uint256 i = 0; i < validators.length; i++) {
            if (i < 10) {
                topValidators[i] = validators[i];
            }
        }
        return topValidators;
    }

    function publishLeaderboard() external {
        address[] memory topValidators = getTopValidators();
        for (uint256 i = 0; i < topValidators.length; i++) {
            emit LeaderboardUpdated(topValidators[i], reputationContract.getReputationScore(topValidators[i]));
        }
    }
}
