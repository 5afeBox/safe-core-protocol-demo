// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IInterchainExecutor } from './interfaces/IInterchainExecutor.sol';
import { InterchainCalls } from './lib/InterchainCalls.sol';

contract InterchainExecutor is IInterchainExecutor, AxelarExecutable, Ownable {
    // Whitelisted callers. The caller is the contract that calls the `InterchainSender` at the source chain.
    mapping(string => mapping(address => bool)) public whitelistedCallers;

    // Whitelisted senders. The sender is the `InterchainSender` contract address at the source chain.
    mapping(string => mapping(string => bool)) public whitelistedSenders;

    constructor(address _gateway, address _owner) AxelarExecutable(_gateway) {
        if (_owner == address(0)) revert InvalidAddress();

        transferOwnership(_owner);
    }

    /**
     * @dev Executes The source address must be a whitelisted sender.
     * @param sourceAddress The source address
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal override {
        // Check that the source address is whitelisted
        if (!whitelistedSenders[sourceChain][sourceAddress]) {
            revert NotWhitelistedSourceAddress();
        }

        // Decode the payload
        (address sourceCaller, InterchainCalls.Call[] memory calls) = abi.decode(
            payload,
            (address, InterchainCalls.Call[])
        );

        // Check that the caller is whitelisted
        if (!whitelistedCallers[sourceChain][sourceCaller]) {
            revert NotWhitelistedCaller();
        }

        _beforeExecuted(sourceChain, sourceAddress, sourceCaller, calls);

        // Execute with the given arguments
        _execute(calls);

        _onExecuted(sourceChain, sourceAddress, sourceCaller, payload);

        emit Executed(keccak256(abi.encode(sourceChain, sourceAddress, sourceCaller, payload)));
    }

    /**
     * @dev Executes the Calls each target with the respective value, signature, and data.
     * @param calls The calls to execute.
     */
    function _execute(InterchainCalls.Call[] memory calls) internal {
        for (uint256 i = 0; i < calls.length; i++) {
            InterchainCalls.Call memory call = calls[i];
            (bool success, bytes memory result) = call.target.call{ value: call.value }(call.callData);

            if (!success) {
                _onTargetExecutionFailed(call, result);
            } else {
                _onTargetExecuted(call, result);
            }
        }
    }

    /**
     * @dev Set the caller whitelist status
     * @param sourceChain The source chain
     * @param sourceCaller The source caller
     * @param whitelisted The whitelist status
     */
    function setWhitelistedCaller(
        string calldata sourceChain,
        address sourceCaller,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedCallers[sourceChain][sourceCaller] = whitelisted;
        emit WhitelistedCallerSet(sourceChain, sourceCaller, whitelisted);
    }

    /**
     * @dev Set the sender whitelist status
     * @param sourceChain The source chain
     * @param sourceSender The source sender
     * @param whitelisted The whitelist status
     */
    function setWhitelistedSender(
        string calldata sourceChain,
        string calldata sourceSender,
        bool whitelisted
    ) external override onlyOwner {
        whitelistedSenders[sourceChain][sourceSender] = whitelisted;
        emit WhitelistedSenderSet(sourceChain, sourceSender, whitelisted);
    }

    /**
     * @dev Receive native tokens for that requires native tokens.
     */
    receive() external payable {}

    /**
     * @param sourceChain The source chain from where the message was sent.
     * @param sourceAddress The source address that sent the message. The source address should be the `InterchainSender` contract address at the source chain.
     * @param caller The caller that calls the `InterchainSender` at the source chain.
     * @param calls The array of `InterchainCalls.Call` to execute. Each call contains the target, value, and callData.
     */
    function _beforeExecuted(
        string calldata sourceChain,
        string calldata sourceAddress,
        address caller,
        InterchainCalls.Call[] memory calls
    ) internal virtual {
        // You can add your own logic here to handle the payload before the message is executed.
    }

    /**
     * @dev A callback function that is called after the message is executed.
     * This function emits an event containing the hash of the payload to signify successful execution.
     * @param payload The payload. It is ABI encoded of the caller and calls.
     * Where:
     * - `caller` is the address that calls the `InterchainSender` at the source chain.
     * - `calls` is the array of `InterchainCalls.Call` to execute. Each call contains the target, value, signature and data.
     */
    function _onExecuted(
        string calldata /* sourceChain */,
        string calldata /* sourceAddress */,
        address /* caller */,
        bytes calldata payload
    ) internal virtual {
        // You can add your own logic here to handle the payload after the message is executed.
    }

    /**
     * @dev A callback function that is called when the execution of a target contract within a message fails.
     * This function will revert the transaction providing the failure reason if present in the failure data.
     * @param result The return data from the failed call to the target contract.
     */
    function _onTargetExecutionFailed(InterchainCalls.Call memory /* call */, bytes memory result) internal virtual {
        // You can add your own logic here to handle the failure of the target contract execution. The code below is just an example.
        if (result.length > 0) {
            // The failure data is a revert reason string.
            assembly {
                revert(add(32, result), mload(result))
            }
        } else {
            // There is no failure data, just revert with no reason.
            revert ExecuteFailed();
        }
    }

    /**
     * @dev Called after a target is successfully executed. The derived contract should implement this function.
     * This function should do some post-execution work, such as emitting events.
     * @param call The call that has been executed.
     * @param result The result of the call.
     */
    function _onTargetExecuted(InterchainCalls.Call memory call, bytes memory result) internal virtual {
        // You can add your own logic here to handle the success of each target contract execution.
    }
}
