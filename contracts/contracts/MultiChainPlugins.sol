// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";
import {ISafe} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeProtocolAction} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {_getFeeCollectorRelayContext, _getFeeTokenRelayContext, _getFeeRelayContext} from "@gelatonetwork/relay-context/contracts/GelatoRelayContext.sol";
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';
import { IInterchainProposalSender } from './interfaces/IInterchainProposalSender.sol';
import { InterchainCalls } from './lib/InterchainCalls.sol';

contract MultiChainPlugin is BasePluginWithEventMetadata, IInterchainSender {
    IAxelarGateway public gateway;
    IAxelarGasService public gasService;
    constructor(
        address _gateway, 
        address _gasService
    )
        BasePluginWithEventMetadata(
            PluginMetadata({
                name: "MultiChain Plugin",
                version: "1.0.0",
                requiresRootAccess: false,
                iconUrl: "",
                appUrl: "https://5afe.github.io/safe-core-protocol-demo/#/multichain/${plugin}"
            })
        )
    {
        if (_gateway == address(0) || _gasService == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(_gateway);
        gasService = IAxelarGasService(_gasService);
    }

    function _sendCrossChainTx(InterchainCalls.InterchainCall memory interchainCall) internal {
        bytes memory payload = abi.encode(msg.sender, interchainCall.calls);

        if (interchainCall.gas > 0) {
            gasService.payNativeGasForContractCall{ value: interchainCall.gas }(
                address(this),
                interchainCall.destinationChain,
                interchainCall.destinationContract,
                payload,
                msg.sender
            );
        }

        gateway.callContract(interchainCall.destinationChain, interchainCall.destinationContract, payload);
    }

    function revertIfInvalidFee(InterchainCalls.InterchainCall[] calldata interchainCalls) private {
        uint totalGas = 0;
        for (uint i = 0; i < interchainCalls.length; ) {
            totalGas += interchainCalls[i].gas;
            unchecked {
                ++i;
            }
        }

        if (totalGas != msg.value) {
            revert InvalidFee();
        }
    }

    function executeFromPlugin(ISafeProtocolManager manager, ISafe safe, bytes calldata data) external {
        // Execute the contract on source chain
        
        // Send cross-chain message to the destination chain
        _sendCrossChainTx(InterchainCalls.InterchainCall(destinationChain, destinationContract, msg.value, calls));
    }
}
