// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ILogic {
    function approveRental() external;
    function rejectRental() external;
    function requestRental() external;
    function publishProperty() external;
    function hideProperty() external;
    function createProperty() external;
    function updateProperty() external;
    function updatePropertyRentalConditons() external;
    function cancelRental() external;
    function renewRental() external;
    function payRent() external;
    function withdraw() external;
}
