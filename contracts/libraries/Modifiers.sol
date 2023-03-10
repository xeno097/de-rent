// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/AppStorage.sol";
import "@contracts/libraries/DeRentNFT.sol";

contract Modifiers {
    using DeRentNFT for AppStorage;

    AppStorage internal s;

    modifier not0Address(address user) {
        if (user == address(0)) {
            revert Errors.InvalidAddress(user);
        }
        _;
    }

    modifier forbidden() {
        revert Errors.ForbiddenOperation();
        _;
    }

    // Properties
    modifier requirePropertyExists(uint256 property) {
        if (property >= s.getCount()) {
            revert Errors.PropertyNotFound();
        }
        _;
    }

    modifier requirePropertyOwner(uint256 property) {
        if (s.ownerOf(property) != msg.sender) {
            revert Errors.NotPropertyOwner();
        }
        _;
    }

    // Rentals
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
