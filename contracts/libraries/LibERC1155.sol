// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts and https://github.com/aavegotchi/aavegotchi-contracts

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "@contracts/libraries/AppStorage.sol";
import "@contracts/libraries/Errors.sol";

library LibERC1155 {
    // Return value from `onERC1155Received` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`).
    bytes4 internal constant ERC1155_ACCEPTED = 0xf23a6e61;

    // Return value from `onERC1155BatchReceived` call if a contract accepts receipt (i.e `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
    bytes4 internal constant ERC1155_BATCH_ACCEPTED = 0xbc197c81;

    // Events
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _value, uint256 indexed _id);

    function _singleTransfer(AppStorage storage s, address from, address to, uint256 id, uint256 amount) private {
        uint256 fromBalance = s.tokenBalances[id][from];

        if (fromBalance < amount) {
            revert Errors.InsufficientBalance();
        }

        unchecked {
            s.tokenBalances[id][from] = fromBalance - amount;
        }
        s.tokenBalances[id][to] += amount;
    }

    function _safeTransferFrom(
        AppStorage storage s,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert Errors.InvalidTransferToAddress(address(0));
        }

        address operator = msg.sender;

        _singleTransfer(s, from, to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);

        onERC1155Received(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        AppStorage storage s,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal {
        if (amounts.length != ids.length) {
            revert Errors.ArrayInputsLengthDoNotMatch();
        }

        if (to == address(0)) {
            revert Errors.InvalidTransferToAddress(address(0));
        }

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; ++i) {
            _singleTransfer(s, from, to, ids[i], amounts[i]);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        onERC1155BatchReceived(operator, from, to, ids, amounts, data);
    }

    function _balanceOf(AppStorage storage s, address account, uint256 id) internal view returns (uint256) {
        if (account == address(0)) {
            revert Errors.InvalidAddress(address(0));
        }

        return s.tokenBalances[id][account];
    }

    function _balanceOfBatch(AppStorage storage s, address[] memory accounts, uint256[] memory ids)
        internal
        view
        returns (uint256[] memory)
    {
        if (accounts.length != ids.length) {
            revert Errors.ArrayInputsLengthDoNotMatch();
        }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = _balanceOf(s, accounts[i], ids[i]);
        }

        return batchBalances;
    }

    function _setApprovalForAll(AppStorage storage s, address owner, address operator, bool approved) internal {
        if (owner == operator) {
            revert Errors.CannotSetApprovalForSelf();
        }

        s.approvals[owner][operator] = approved;

        emit ApprovalForAll(owner, operator, approved);
    }

    function _isApprovedForAll(AppStorage storage s, address account, address operator) internal view returns (bool) {
        return s.approvals[account][operator];
    }

    // Extra
    function _mint(AppStorage storage s, address to, uint256 id, uint256 amount, bytes memory data) internal {
        if (to == address(0)) {
            revert Errors.InvalidTransferToAddress(address(0));
        }

        address operator = msg.sender;
        address from = address(0);

        s.tokenBalances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);

        onERC1155Received(operator, from, to, id, amount, data);
    }

    function _mintBatch(
        AppStorage storage s,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal {
        if (to == address(0)) {
            revert Errors.InvalidTransferToAddress(address(0));
        }

        if (amounts.length != ids.length) {
            revert Errors.ArrayInputsLengthDoNotMatch();
        }

        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            s.tokenBalances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        onERC1155BatchReceived(operator, address(0), to, ids, amounts, data);
    }

    function _burn(AppStorage storage s, address from, uint256 id, uint256 amount) internal {
        if (from == address(0)) {
            revert Errors.InvalidBurnFromAddress(from);
        }

        address operator = msg.sender;
        address to = address(0);

        _singleTransfer(s, from, to, id, amount);

        emit TransferSingle(operator, from, to, id, amount);
    }

    function _burnBatch(AppStorage storage s, address from, uint256[] memory ids, uint256[] memory amounts) internal {
        if (from == address(0)) {
            revert Errors.InvalidBurnFromAddress(from);
        }

        if (amounts.length != ids.length) {
            revert Errors.ArrayInputsLengthDoNotMatch();
        }

        address operator = msg.sender;
        address to = address(0);

        for (uint256 i = 0; i < ids.length; i++) {
            _singleTransfer(s, from, to, ids[i], amounts[i]);
        }

        emit TransferBatch(operator, from, to, ids, amounts);
    }

    function _uri(AppStorage storage s, uint256 tokenId) internal view returns (string memory) {
        string memory tokenURI = s.tokenUris[tokenId];

        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(s.baseUri, tokenURI)) : tokenURI;
    }

    function _setURI(AppStorage storage s, uint256 tokenId, string memory tokenURI) internal {
        s.tokenUris[tokenId] = tokenURI;

        emit URI(_uri(s, tokenId), tokenId);
    }

    // ERC1155 checks
    function onERC1155Received(
        address _operator,
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (
            size > 0
                && ERC1155_ACCEPTED != IERC1155Receiver(_to).onERC1155Received(_operator, _from, _id, _value, _data)
        ) {
            revert Errors.InvalidTransferToAddress(_to);
        }
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (
            size > 0
                && ERC1155_BATCH_ACCEPTED
                    != IERC1155Receiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data)
        ) {
            revert Errors.InvalidTransferToAddress(_to);
        }
    }
}
