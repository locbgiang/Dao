// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Ownable
 * @author Loc Giang
 * @notice This is a simple ownable contract
 * Inherits from OpenZeppelin's Ownable, which restricts certain functions to single "owner" address
 */
contract Box is Ownable {
    // a single private number stored on-chain
    uint256 private value;

    // Emitted whenever the value is updated, letting off-chain listeners (like a frontend or indexer)
    // track changes
    event ValueChanged(uint256 newValue);

    // Ownable(msg.sender) in the constructor sets the deployer as the initial owner.
    constructor() Ownable(msg.sender) {}

    // modifier onlyOwner restricts this to the contract owner only
    // updates value and emits ValueChanged
    // reverts if called by anyone other than the owner
    function store(uint256 newValue) public onlyOwner {
        value = newValue;
        emit ValueChanged(newValue);
    }

    // view function, callable by anyone (no restriction)
    // returns the currently stored value
    // no gas cost when called externally (read-only)
    function retrieve() public view returns (uint256) {
        return value;
    }

    /**
     * Typical Use Case
     * This pattern is often used to demonstrate
     *  asscess control (onlyOwner) in solidity
     *  upgradeable contract patterns 
     */
}