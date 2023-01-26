// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Constants {
    uint256 public constant CONTRACT_DURATION = 52 weeks; // ~ 1 year

    uint256 public constant RENTAL_REQUEST_NUMBER_OF_DEPOSITS = 2;

    uint256 public constant MIN_RENT_PRICE = 0.02 ether;

    uint256 public constant MONTH = 30 days;

    uint256 public constant ON_TIME_PAYMENT_DEADLINE = 2 days;

    uint256 public constant LATE_PAYMENT_DEADLINE = ON_TIME_PAYMENT_DEADLINE + 2 days;
}
