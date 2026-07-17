// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";

/**
 * @title GovToken
 * @author Loc Giang
 * @notice This is a governance token contract used to give holders voting power in a DAO
 * this is the token that will be used with a governor contract to vote on proposals through governance
 */
// ERC20 - standard fungible token (transfer, balanceOf, ect)
// ERC20Permit - adds gasless approvals via signatures (EIP-2612) - lets users approve
// spending without an on-chain approve() tx
// ERC20Votes - adds on-chain voting power tracking using checkpoints - required for OpenZeppelin
// Governor contract
contract GovToken is ERC20, ERC20Permit, ERC20Votes {
    // set token name "My Token" and symbol. "MTK" 
    // initializes EIP-712 domain for permit signatures
    constructor() ERC20("My Token", "MTK") ERC20Permit("My Token") {}

    // the following functions are overrides required by solidity
    // publicly mintable (no access control) - anyone can mint tokens
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // required because both ERC20 and ERC20Votes define _update
    // (the internal function that runs on every transfer/mint/burn) 
    // ERC20Votes uses this hook to update voting power checkpoints whenever balances change
    // super._update(...) ensures both parent implementation runs correctly
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        super._update(from, to, amount);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}