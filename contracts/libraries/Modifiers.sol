// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/AppStorage.sol";

contract Modifiers {
    AppStorage internal s;

    modifier not0Address(address user) {
        if (user == address(0)) {
            revert Errors.InvalidAddress(user);
        }
        _;
    }

    modifier onlyPropertyOwner(uint256 property) {
        if (s.propertyInstance.ownerOf(property) != msg.sender) {
            revert Errors.NotPropertyOwner();
        }
        _;
    }

    modifier onlyPropertyTenant(uint256 property) {
        if (s.rentals[property].tenant != msg.sender) {
            revert Errors.NotPropertyTenant();
        }
        _;
    }

    modifier onlyPendingRentalRequest(uint256 request) {
        if (s.rentals[request].status != DataTypes.RentalStatus.Pending) {
            revert Errors.CannotApproveNotPendingRentalRequest();
        }
        _;
    }

    modifier propertyExist(uint256 property) {
        if (!s.propertyInstance.exists(property)) {
            revert Errors.PropertyNotFound();
        }
        _;
    }

    modifier requireApprovedRentalRequest(uint256 request) {
        if (s.rentals[request].status != DataTypes.RentalStatus.Approved) {
            revert Errors.RentalNotApproved();
        }
        _;
    }

    modifier requireRentalCompletionDateReached(uint256 request) {
        if (block.timestamp <= s.rentals[request].createdAt + Constants.CONTRACT_DURATION) {
            revert Errors.RentalCompletionDateNotReached();
        }
        _;
    }
}
