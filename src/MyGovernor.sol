// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

/**
 * @title MyGovernor
 * @author Loc Giang
 * @notice This is the core DAO governance contract - it ties together the GovToken(voting power)
 * and a TimelockController (execution delay) to let token holder propose, vote on, and execute
 * on-chain actions (like calling Box.store()).
 * 
 * Governor - Base contract: proposal creation, voting, state machine
 * GovernorSettings - Configurable voting delay, voting period, proposal threshold
 * GovernorCountingSimple - Simple For/Against/Abstain vote counting
 * GovernorVotes - Reads voting power from an IVotes token (your GovToken)
 * GovernorVotesQuorumFraction - Quorum define as a % of total token supply
 * GovernorTimelockControl - Routes proposal execution through a TimelockController (adds a delay
 * + separates proposal passing from execution)
 */

/**
 * How the whole DAO flow works together
 * 1. Token holder delegates voting power (GovToken.delegate())
 * 2. Anyone calls governor.propose(targets, values, calldatas, description)
 *      - e.g., targets=[Box], calldatas=[abi.encodeCall(Box.store, (42))]
 * 3. After votingDelay, voting opens for votingPeriod blocks
 * Holders call governor.castVote[proposalId, support]
 * 4. If quorum reached & majority "For" - proposal succeeds
 */
contract MyGovernor is 
    Governor,   
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /**
     * @param _token GovToken (must implement IVotes, satisfied by ERC20Votes)
     * @param _timelock a TimelockController that will actually execute passed proposals
     * GovernorSettings(1, 50400, 0):
     *      Voting delay: 1 block - how long after proposing before voting starts
     *      Voting period: 50400 blocks (~1 week, assuming~12s blocks)
     *      Proposal threshold: 0 - mininum votes needed to create a proposal (0 = anone can propose)
     * GovernorVotesQuorumFraction(4) - quorum = 4% of total token supply (at proposal snapshot block)
     * must vote for the proposal to be valid.
     */
    constructor (IVotes _token, TimelockController _timelock) 
        Governor("MyGovernor")
        GovernorSettings(1, /* 1 block */ 50400, /* 1 week */ 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity

    function votingDelay() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber) 
        public 
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    // returns the current lifecycle stage of a proposal
    // pending -active -canceled/defeated/succeeded - queue - execute
    // Governor defines the base logic
    // GovernorTimelockControl overrides it to add the queue state -
    // checking whether the operation has been queued/executed in TimelockController
    function state(uint256 proposalId) 
        public 
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    } 
`   
    function propose (
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function proposalNeedsQueuing(uint256 proposalId) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(proposalId);
    }

    /**
     * Called internally when someone invokes governor.queue(...) on
     * a succeeded proposal
     * 
     * GovernorTimelockControl's implementation forwards the targets/values/calldatas to
     * TimelockController.scheduleBatch(...) starting the timelock's mandatory delay countown
     * 
     * Returns a uint8 - the timestamp when the operation becomes executable 
     */
    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * called internally when someone invokes governor.execute(...) after timelock delay has passed
     * GovernorTimelockControl's version calls TimelockController itself as msg.sender
     * This is why Box's owner should be set to the TimelockController address, not the Governor
     * or an EOA
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(proposalId, targets, values, calldatas, descriptionHash);
    }

    /**
     * Allows canceling a proposal before it's executed (e.g. proposer cancels or it's canceled
     * via governance rules)
     * 
     * GovernorTimelockControl's version also cancels the corresponding queue operation in the 
     * TimelockController (ifit was already queued), keeping both systems in sync.
     */
    function _cancel (
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId) 
        public 
        view
        override(Governor)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}