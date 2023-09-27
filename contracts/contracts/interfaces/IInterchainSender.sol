// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { InterchainCalls } from '../lib/InterchainCalls.sol';

interface IInterchainSender {
    // An error emitted when the given gas is invalid
    error InvalidFee();

    // An error emitted when the given address is invalid
    error InvalidAddress();

    /**
     * @param calls An array of calls to be executed at the destination chain
     */
    function sendCrossChainTxs(InterchainCalls.InterchainCall[] memory calls) external payable;

    /**
     * @param destinationChain destination chain
     * @param destinationContract destination contract
     * @param calls An array of calls to be executed at the destination chain
     */
    function sendCrossChainTx(
        string calldata destinationChain,
        string calldata destinationContract,
        InterchainCalls.Call[] calldata calls
    ) external payable;
}
