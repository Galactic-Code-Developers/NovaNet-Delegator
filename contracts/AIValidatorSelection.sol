// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./NovaNetValidator.sol";
import "./AIValidatorReputation.sol";

contract AIValidatorSelection is Ownable {
    NovaNetValidator public validatorContract;
    AIValidatorReputation public reputationContract;

    struct ValidatorScore {
        address validator;
        uint256 performanceScore;
        uint256 reputationScore;
        uint256 totalScore;
    }

    event ValidatorRanked(address indexed validator, uint256 totalScore);
    event BestValidatorSelected(address indexed bestValidator);

    constructor(address _validatorContract, address _reputationContract) {
        validatorContract = NovaNetValidator(_validatorContract);
        reputationContract = AIValidatorReputation(_reputationContract);
    }

    /// @notice Calculates AI-driven ranking for validators
    /// @return Ranked list of validators with AI scores
    function rankValidators() public view returns (ValidatorScore[] memory) {
        address[] memory validators = validatorContract.getValidators();
        ValidatorScore[] memory scores = new ValidatorScore[](validators.length);

        for (uint256 i = 0; i < validators.length; i++) {
            uint256 performanceScore = validatorContract.getPerformance(validators[i]);
            uint256 reputationScore = reputationContract.getReputation(validators[i]);
            uint256 totalScore = (performanceScore * 60 / 100) + (reputationScore * 40 / 100); // AI-weighted scoring

            scores[i] = ValidatorScore(validators[i], performanceScore, reputationScore, totalScore);
        }

        return scores;
    }

    /// @notice Selects the best validator based on AI rankings
    /// @return Address of the best validator
    function selectBestValidator() public view returns (address) {
        ValidatorScore[] memory scores = rankValidators();
        address bestValidator = address(0);
        uint256 highestScore = 0;

        for (uint256 i = 0; i < scores.length; i++) {
            if (scores[i].totalScore > highestScore) {
                highestScore = scores[i].totalScore;
                bestValidator = scores[i].validator;
            }
        }

        emit BestValidatorSelected(bestValidator);
        return bestValidator;
    }

    /// @notice Recommends validators to delegators
    /// @param delegator Address of the delegator
    function recommendValidatorForDelegator(address delegator) external view returns (address) {
        address bestValidator = selectBestValidator();
        require(bestValidator != address(0), "No suitable validators available.");
        return bestValidator;
    }
}
