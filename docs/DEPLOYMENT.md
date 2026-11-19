# Deployment plan — BountybotRegistry on BNB Chain

**Status: PREPARED ONLY. No transaction has been sent. No gas spent.**

Deployment requires parent/user approval. This document gives the exact
command, the exact cost, and the verification steps — nothing is hidden.

## Target

- Chain: BNB Chain mainnet (chain id 56)
- Contract: `BountybotRegistry` (`src/BountybotRegistry.sol`, Solidity 0.8.24,
  optimizer on, 200 runs)
- Constructor argument: Agent ID contract
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` (SPACE ID Agent ID, ERC-721)
- Deployer: Binance Agentic Wallet `0x4Fbb7839AE388f166E92B736BC7C8f1A45d8713E`
  (holder of Agent ID `kontoru.ai`, `balanceOf = 1` verified live) or the
  owner wallet — parent decides at approval time.

## Dry-run result (simulated on live BSC mainnet, 18 Nov 2026 ~19:20 WIB)

Command (dummy key, simulation only — no broadcast):

```bash
forge script script/Deploy.s.sol --rpc-url https://bsc-dataseed.binance.org
```

Result:

- Simulated deployment address (dummy key): `0x98095F39B345062210DF16B3002638463E0E0044`
  (the real address will differ — it depends on the deployer address + nonce)
- Estimated total gas for script: **1,771,741**
- Estimated gas price: **0.05 gwei** (live from the RPC at dry-run time)
- Estimated amount required: **0.00008858705 BNB**

Independent cross-check (`forge test --gas-report`): contract creation cost
**1,362,878 gas**, deployment size 6,256 bytes. The dry-run total is higher
because it includes the script's broadcast setup; the dry-run number is the
one to budget.

## Cost table (BNB $589.47, CoinGecko, 18 Nov 2026 ~19:14 WIB)

| Gas price | Deployment cost (1,771,741 gas) | USD |
|---|---|---|
| 0.05 gwei (live at dry-run) | 0.0000886 BNB | ~$0.05 |
| 1 gwei (conservative) | 0.0017717 BNB | ~$1.04 |
| 3 gwei (busy) | 0.0053152 BNB | ~$3.13 |
| 5 gwei (busy) | 0.0088587 BNB | ~$5.22 |

Per-interaction gas (avg, `forge --gas-report`):

| Function | Gas (avg) | Cost at 1 gwei | Cost at 0.05 gwei |
|---|---|---|---|
| `registerHunter` | 64,361 | ~$0.04 | ~$0.002 |
| `postBounty` | 140,691 | ~$0.08 | ~$0.004 |
| `submitFinding` | 102,783 | ~$0.06 | ~$0.003 |
| `acceptFinding` | 66,258 | ~$0.04 | ~$0.002 |
| `cancelBounty` | 59,553 | ~$0.03 | ~$0.002 |

**Total to go live: deployment only (~$0.05–$1.04).** Interactions are
paid by whoever calls them (poster/hunter), at cents or less.

## Deploy command (runs only with approval)

```bash
# 1. Set the deployer key in the environment (never commit it, never paste it in chat)
export PRIVATE_KEY=<deployer private key>

# 2. Deploy + verify on BscScan in one step (needs a BscScan API key)
forge script script/Deploy.s.sol \
  --rpc-url https://bsc-dataseed.binance.org \
  --broadcast --verify \
  --etherscan-api-key $BSCSCAN_API_KEY

# 3. Record the deployed address, then verify it:
#    - BscScan: contract source verified + open-source
#    - cast code <address> --rpc-url https://bsc-dataseed.binance.org
#    - cast call <address> "agentId()" --rpc-url https://bsc-dataseed.binance.org
#      (must return 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F)
```

## BscScan verification (required by the hackathon)

- Source must be verified and public on BscScan. `--verify` in the command
  above does this automatically (uses the BscScan API).
- If verification is done separately: `forge verify-contract <address>
  src/BountybotRegistry.sol:BountybotRegistry --chain-id 56
  --etherscan-api-key $BSCSCAN_API_KEY --compiler-version v0.8.24+commit.e11b9ed9`
- After verification, confirm on bscscan.com that the source is visible and
  the "Read Contract" tab shows `agentId()` =
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.

## After deployment (before submitting)

1. `registerHunter("kontoru.ai")` from the deployer wallet (proves the
   flow works end to end with a real Agent ID holder).
2. Post a small test bounty, submit a test finding, accept it — on mainnet,
   with tiny amounts — to prove the full loop live.
3. Record the contract address + transaction hashes for the submission form.
4. Publish this repo publicly on GitHub (open-source requirement) and link
   it in the submission.

## What deployment does NOT do

- No token is created. No mint. No fees. No admin keys.
- The deployer gets **no special powers**: the contract has no owner.
  Deploying only creates the registry; it does not grant control over it.
