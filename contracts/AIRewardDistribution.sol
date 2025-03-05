// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AIValidatorRewards.sol";

contract AIRewardDistribution {
    AIValidatorRewards public rewardsContract;

    event ValidatorPaid(address indexed validator, uint256 amount);

    constructor(address _rewardsContract) {
        rewardsContract = AIValidatorRewards(_rewardsContract);
    }

    function distributeRewardsToTopValidators(address[] memory topValidators) external {
        for (uint256 i = 0; i < topValidators.length; i++) {
            rewardsContract.distributeRewards(topValidators[i]);
            emit ValidatorPaid(topValidators[i], rewardsContract.rewards(topValidators[i]));
        }
    }
}
