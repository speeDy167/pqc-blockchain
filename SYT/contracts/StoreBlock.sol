// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BlockDataStorage {
    struct BlockData {
        bytes32 blockHash;
        bytes32 parentHash;
        bytes32 transactionsRoot;
    }

    BlockData public lastBlockData;

    // Function to store the block data
    function storeBlockData(
        bytes32 _blockHash,
        bytes32 _parentHash,
        bytes32 _transactionsRoot
    ) public {
        lastBlockData = BlockData({
            blockHash: _blockHash,
            parentHash: _parentHash,
            transactionsRoot: _transactionsRoot
        });
    }

    // Function to retrieve the stored block data (optional)
    function getBlockData() public view returns (BlockData memory) {
        return lastBlockData;
    }
}
