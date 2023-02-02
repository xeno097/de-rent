// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiverFacet is IERC1155TokenReceiver {
    /**
     *  @dev see {ERC1155TokenReceiver-onERC1155Received}.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     *  @dev see {ERC1155TokenReceiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
