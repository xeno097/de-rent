// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/libraries/LibERC1155.sol";
import "@contracts/libraries/AppStorage.sol";

/// @dev Wrapper lib around the LibERC1155 to make it easier to manipulate user balances.
library DeRentToken {
    using LibERC1155 for AppStorage;

    function balanceOf(AppStorage storage s, address user) internal view returns (uint256) {
        return s._balanceOf(user, Constants.DE_RENT_USER_BALANCES_TOKEN_ID);
    }

    function mint(AppStorage storage s, address to, uint256 amount) internal {
        s._mint(to, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, amount, bytes(""));
    }

    function transfer(AppStorage storage s, address from, address to, uint256 amount) internal {
        s._safeTransferFrom(from, to, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, amount, bytes(""));
    }

    function burn(AppStorage storage s, address from, uint256 amount) internal {
        s._burn(from, Constants.DE_RENT_USER_BALANCES_TOKEN_ID, amount);
    }
}
