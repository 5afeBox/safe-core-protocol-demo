// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInterchainExecutor {

    event WhitelistedCallerSet(string indexed sourceChain, address indexed sourceCaller, bool whitelisted);

    event WhitelistedSenderSet(string indexed sourceChain, string sourceSender, bool whitelisted);

    event Executed(bytes32 indexed payloadHash);

    error ExecuteFailed();

    error NotWhitelistedCaller();

    error NotWhitelistedSourceAddress();

    /**
     * @param sourceChain The source chain
     * @param sourceSender The source interchain sender address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedSender(
        string calldata sourceChain,
        string calldata sourceSender,
        bool whitelisted
    ) external;

    /**
     * @param sourceChain The source chain
     * @param sourceCaller The source interchain caller address
     * @param whitelisted The whitelisted status
     */
    function setWhitelistedCaller(string calldata sourceChain, address sourceCaller, bool whitelisted) external;
}
