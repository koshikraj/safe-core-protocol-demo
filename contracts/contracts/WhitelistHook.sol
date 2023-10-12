// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.18;

import {IAccount} from "@safe-global/safe-core-protocol/contracts/interfaces/Accounts.sol";
import {ISafeProtocolManager} from "@safe-global/safe-core-protocol/contracts/interfaces/Manager.sol";
import {SafeTransaction, SafeRootAccess} from "@safe-global/safe-core-protocol/contracts/DataTypes.sol";
import {BasePluginWithEventMetadata, PluginMetadata} from "./Base.sol";


contract WhitelistHook is BasePluginWithEventMetadata {

    // safe account => account => whitelist status
    mapping(address => mapping(address => bool)) public whitelistedAddresses;
    mapping(address => bool) public globalWhitelistedAddresses;

    event AddressWhitelisted(address indexed safeAccount, address indexed account);
    event AddressRemovedFromWhitelist(address indexed safeAccount, address indexed account);

    error AddressNotWhiteListed(address account);

    constructor(address[] memory accounts) BasePluginWithEventMetadata(
            PluginMetadata({name: "Whitelist Hook", version: "1.0.0", requiresRootAccess: false, iconUrl: "", appUrl: ""})
        )
    {

       for (uint i = 0; i < accounts.length; i++) {
            globalWhitelistedAddresses[accounts[i]] = true;
            emit AddressWhitelisted(address(0), accounts[i]);
        }
    }


    /** 
     * @notice Adds accounts to whitelist mapping.
     *         The caller should be a Safe account.
     * @param accounts addresses of the accounts to be whitelisted
     */
    function addToWhitelist(address[] memory accounts) external {

        for (uint i = 0; i < accounts.length; i++) {
            whitelistedAddresses[msg.sender][accounts[i]] = true;
            emit AddressWhitelisted(msg.sender, accounts[i]);
        }
    }

    /**
     * @notice Removes accounts from whitelist mapping.
     *         The caller should be a Safe account.
     * @param accounts addresses of the accountes to be removed from the whitelist
     */
    function removeFromWhitelist(address[] memory accounts) external {

         for (uint i = 0; i < accounts.length; i++) {
            whitelistedAddresses[msg.sender][accounts[i]] = false;
            emit AddressRemovedFromWhitelist(msg.sender, accounts[i]);
         }
    }

    /**
     * @notice A function that will be called before the execution of a transaction if the hooks are enabled
     * @dev Add custom logic in this function to validate the pre-state and contents of transaction for root access.
     * @param account Address of the account
     * @param tx SafeTransaction
     * @param executionType uint256
     * @param executionMeta bytes
     * @return preCheckData bytes
     */
      function preCheck(
        IAccount account,
        SafeTransaction calldata tx,
        uint256 executionType,
        bytes calldata executionMeta
    ) external view returns (bytes memory preCheckData) {


        (address to, uint256 value,
            bytes memory data,
            uint256 safeTxGas,
            uint256 baseGas,
            uint256 gasPrice,
            address gasToken,
            address refundReceiver,
            bytes memory signatures,
            address msgSender ) = abi.decode(executionMeta, (address, uint256, bytes, uint256, uint256, uint256, address, address, bytes, address));    

        require(whitelistedAddresses[address(account)][to] || globalWhitelistedAddresses[to], "Address not in the whitelist");

    }

    /**
     * @notice A function that will be called before the execution of a transaction if the hooks are enabled and
     *         transaction requies root access.
     * @dev Add custom logic in this function to validate the pre-state and contents of transaction for root access.
     * @param account Address of the account
     * @param rootAccess DataTypes.SafeRootAccess
     * @param executionType uint256
     * @param executionMeta bytes
     * @return preCheckData bytes
     */
    function preCheckRootAccess(
        IAccount account,
        SafeRootAccess calldata rootAccess,
        uint256 executionType,
        bytes calldata executionMeta
    ) external returns (bytes memory preCheckData) {

    }

    /**
     * @notice A function that will be called after the execution of a transaction if the hooks are enabled. Hooks should revert if the post state of after the transaction is not as expected.
     * @dev Add custom logic in this function to validate the post-state after the transaction is executed.
     * @param account Address of the account
     * @param success bool
     * @param preCheckData Arbitrary length bytes that was returned by during pre-check of the transaction.
     */
    function postCheck(IAccount account, bool success, bytes calldata preCheckData) external {}

    function requiresPermissions() external view returns (uint8 permissions) {}
}