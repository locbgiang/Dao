// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Box} from "../src/Box.sol";
import {console2} from "forge-std/console2.sol";

contract MyGovernorTest is Test {
    GovToken token;
    TimeLock timelock;
    MyGovernor governor;
    Box box;

    uint256 public constant MIN_DELAY = 3600; // 1 hour - after a vote passes, you have 1 hour before you can enact
    uint256 public constant QUORUM_PERCENTAGE = 4; // Need 4% of voters to pass
    uint256 public constant VOTING_PERIOD = 50400 // this is how long voting lasts
    uint256 public constant VOTING_DELAY = 1; // How many blocks till a proposal vote becomes active

    address[] proposers;
    address[] executors;

    bytes[] functionCalls;
    address[] addressesToCall;
    uint256[] values;

    address public constant VOTER = address(1);

    function setUp() public {
        token = new GovToken();
        token.mint(VOTER, 100e18);

        vm.prank(VOTER);
        token.delegate(VOTER);
    }
}