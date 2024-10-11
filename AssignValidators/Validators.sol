// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ValidatorManager {
    address public owner;
    address[] public proposedValidators;

    event ValidatorProposed(address validator);
    event ValidatorRemoved(address validator);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can propose validators");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // Propose a new validator for Network 1
    function proposeValidator(address _newValidator) public onlyOwner {
        proposedValidators.push(_newValidator);
        emit ValidatorProposed(_newValidator);
    }

    // Propose to remove a validator from Network 1
    function removeValidator(address _validator) public onlyOwner {
        for (uint i = 0; i < proposedValidators.length; i++) {
            if (proposedValidators[i] == _validator) {
                proposedValidators[i] = proposedValidators[proposedValidators.length - 1];
                proposedValidators.pop();
                emit ValidatorRemoved(_validator);
                break;
            }
        }
    }

    // Retrieve proposed validators
    function getProposedValidators() public view returns (address[] memory) {
        return proposedValidators;
    }
}
