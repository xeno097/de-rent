// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/DataTypes.sol";
import "@contracts/libraries/ScoreCounters.sol";
import "@contracts/libraries/Events.sol";
import "@contracts/libraries/AppStorage.sol";

library ReputationWriter {
    using ScoreCounters for ScoreCounters.ScoreCounter;

    function scoreProperty(AppStorage storage s, uint256 property, uint256 score) internal {
        s.propertyScores[property].add(score);

        emit Events.PropertyScored(property, score);
    }

    function scoreUser(AppStorage storage s, address user, uint256 score) internal {
        s.userScores[user].add(score);

        emit Events.UserScored(user, score);
    }

    function scoreUserPaymentPerformance(AppStorage storage s, address user, bool paidOnTime) internal {
        uint256 score = paidOnTime ? Constants.MAX_SCORE : Constants.MIN_SCORE;

        s.userPaymentPerformanceScores[user].add(score);

        emit Events.UserPaymentPerformanceScored(user, score);
    }
}
