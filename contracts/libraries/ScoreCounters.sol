// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/Constants.sol";
import "@contracts/libraries/Errors.sol";

library ScoreCounters {
    struct ScoreCounter {
        uint256 _totalScore;
        uint256 _voteCount;
    }

    function current(ScoreCounter storage counter) internal view returns (uint256) {
        if (counter._voteCount == 0) {
            return Constants.MAX_SCORE * Constants.SCORE_MULTIPLIER;
        }

        return (counter._totalScore * Constants.SCORE_MULTIPLIER) / counter._voteCount;
    }

    function add(ScoreCounter storage counter, uint256 score) internal {
        if (score < Constants.MIN_SCORE || score > Constants.MAX_SCORE) {
            revert Errors.ScoreValueOutOfRange(Constants.MIN_SCORE, Constants.MAX_SCORE);
        }

        counter._totalScore += score;
        counter._voteCount += 1;
    }
}
