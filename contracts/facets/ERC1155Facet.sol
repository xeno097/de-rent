// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@contracts/interfaces/IERC1155.sol";
import "@contracts/libraries/Modifiers.sol";
import "@contracts/libraries/LibERC1155.sol";
import "@contracts/libraries/AppStorage.sol";

contract ERC1155Facet is Modifiers, IERC1155, ERC1155Metadata_URI {
    using LibERC1155 for AppStorage;

    /**
     *  @dev see {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data)
        external
        forbidden
    {}

    /**
     *  @dev see {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external forbidden {}

    /**
     *  @dev see {IERC1155-balanceOf}.
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256) {
        return s._balanceOf(owner, id);
    }

    /**
     *  @dev see {IERC1155-balanceOfBatch}.
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory)
    {
        return s._balanceOfBatch(owners, ids);
    }

    /**
     *  @dev see {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address _operator, bool _approved) external forbidden {}

    /**
     *  @dev see {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return s._isApprovedForAll(owner, operator);
    }

    /**
     *  @dev see {ERC1155Metadata_URI-uri}.
     */
    function uri(uint256 id) external view returns (string memory) {
        return s._uri(id);
    }
}
