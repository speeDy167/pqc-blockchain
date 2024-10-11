// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BlockValidatorStore {

    // Structure to hold block and validator data
    struct BlockInfo {
        bytes32 blockHash;       // Hash of the block
        address[] validators;    // Validators who verified this block
    }

    // Mapping to store block information by block hash
    mapping(bytes32 => BlockInfo) public blocks;

    // Event to notify when new block data is stored
    event BlockStored(bytes32 blockHash, address[] validators);

    // Function to store block data and its validators
    function storeBlock(bytes32 _blockHash, address[] memory _validators) public {
        // Store the block information using blockHash as the key
        BlockInfo memory newBlock = BlockInfo({
            blockHash: _blockHash,
            validators: _validators
        });

        blocks[_blockHash] = newBlock;

        // Emit an event for external listeners
        emit BlockStored(_blockHash, _validators);
    }

    // Function to retrieve validators of a specific block by block hash
    function getBlockValidators(bytes32 _blockHash) public view returns (address[] memory) {
        return blocks[_blockHash].validators;
    }

    // Function to retrieve the block hash of a specific block by block hash
    function getBlockHash(bytes32 _blockHash) public view returns (bytes32) {
        return blocks[_blockHash].blockHash;
    }

    // Function to get both the block hash and validators for a specific block
    function getBlockDetails(bytes32 _blockHash) public view returns (bytes32, address[] memory) {
        BlockInfo memory blockInfo = blocks[_blockHash];
        return (blockInfo.blockHash, blockInfo.validators);
    }
}
