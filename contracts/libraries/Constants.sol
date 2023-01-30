// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Constants {
    uint256 public constant CONTRACT_DURATION = 52 weeks; // ~ 1 year

    /**
     * @dev The number of rent payments that must be deposited as collateral on rental creation.
     */
    uint256 public constant RENTAL_REQUEST_NUMBER_OF_DEPOSITS = 2;

    uint256 public constant MIN_RENT_PRICE = 0.02 ether;

    uint256 public constant MONTH = 30 days;

    /**
     * @dev The maximum number of days after payRentDay that a rent payment can be classified as on time.
     */
    uint256 public constant ON_TIME_PAYMENT_DEADLINE = 2 days;

    /**
     * @dev The maximum number of days after `payRentDay` that a rent payment must be made.
     */
    uint256 public constant LATE_PAYMENT_DEADLINE = ON_TIME_PAYMENT_DEADLINE + 2 days;

    /**
     * @dev The number of decimal digits used to represent a score.
     */
    uint256 public constant DECIMALS = 9;

    /**
     * @dev The number used to format a score representation.
     */
    uint256 public constant SCORE_MULTIPLIER = 10 ** DECIMALS;

    uint256 public constant MAX_SCORE = 5;

    uint256 public constant MIN_SCORE = 1;
}
