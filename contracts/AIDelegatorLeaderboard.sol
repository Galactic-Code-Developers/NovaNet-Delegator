// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIDelegatorLeaderboard is Ownable {
    struct DelegatorRank {
        address delegator;
        uint256 stakeAmount;
        uint256 governanceParticipation;
        uint256 totalScore;
    }

    DelegatorRank[] public leaderboard;

    event LeaderboardUpdated(address indexed delegator, uint256 score);

    function updateLeaderboard(address delegator, uint256 stakeAmount, uint256 governanceParticipation) external onlyOwner {
        uint256 score = (stakeAmount * 60 / 100) + (governanceParticipation * 40 / 100);
        leaderboard.push(DelegatorRank(delegator, stakeAmount, governanceParticipation, score));

        emit LeaderboardUpdated(delegator, score);
    }

    function getLeaderboard() external view returns (DelegatorRank[] memory) {
        return leaderboard;
    }
}
