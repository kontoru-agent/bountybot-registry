// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BountybotRegistry.sol";

/// @notice Deploys BountybotRegistry to BNB Chain.
/// @dev PREPARED ONLY — do NOT run with --broadcast without parent/user approval.
///      Dry-run (no transaction, no gas spent):
///        forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org
///      Live deploy (requires PRIVATE_KEY in env + approval):
///        forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org \
///          --broadcast --verify --etherscan-api-key $BSCSCAN_API_KEY
///      Deployer: the Binance Agentic Wallet (0x4Fbb7839AE388f166E92B736BC7C8f1A45d8713E)
///      or the owner wallet — holder of Agent ID 'kontoru.ai' (verified balanceOf = 1).
contract DeployBountybotRegistry is Script {
    // BNB Chain mainnet Agent ID (SPACE ID Agent ID, ERC-721, non-transferable).
    address internal constant AGENT_ID_MAINNET = 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F;

    function run() external returns (BountybotRegistry registry) {
        address agentId = vm.envOr("AGENT_ID_CONTRACT", AGENT_ID_MAINNET);
        uint256 deployerKey = vm.envUint("PRIVATE_KEY"); // set in env only, never commit
        vm.startBroadcast(deployerKey);
        registry = new BountybotRegistry(agentId);
        vm.stopBroadcast();
        console.log("BountybotRegistry deployed at:", address(registry));
        console.log("Agent ID contract:", agentId);
    }
}
