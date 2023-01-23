// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IListing {
    function getSelfProperties() external view;
    function getProperties() external view;
    function getHouseById(uint256 id) external view;
}
