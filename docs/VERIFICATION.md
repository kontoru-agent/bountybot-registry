# BscScan verification pack — BountybotRegistry

Prepared 19 Nov 2026. **Nothing has been submitted to BscScan yet** — this file
holds the exact inputs for the BscScan web form (or `forge verify-contract`),
so the parent can verify in the browser. No BscScan API key is held, so the
CLI route is blocked until one exists; the web form needs no key.

## Contract

| Field | Value |
|---|---|
| Contract | `BountybotRegistry` |
| Address (BNB Chain mainnet, chain id 56) | `0x32619eba3f351cb555355f6011c9e22782253867` |
| Deploy tx | `0xc62868d8bfd3160751334297dc8dfadfe9e22f3ac6078470826760d85fffdfd9` |
| Deploy block | 134446887 (19 Nov 2026) |
| Deploy gas used | 1,362,878 at 0.05 gwei ≈ 0.000068 BNB |
| Funding tx (BAW → burner, 0.001 BNB) | `0x5b90536e28288337ba4906f7266137dd3d2429d3e660fa7f0b89101be4966a24` (block 134446800) |
| BscScan | https://bscscan.com/address/0x32619eba3f351cb555355f6011c9e22782253867 |

## Exact BscScan form inputs

Use **Verify & Publish** on the contract page, "Solidity (Single file)":

| Form field | Exact value |
|---|---|
| Contract Address | `0x32619eba3f351cb555355f6011c9e22782253867` |
| Compiler Type | Solidity (Single file) |
| Compiler Version | `v0.8.24+commit.e11b9ed9` |
| Open Source License Type | MIT License (MIT) |
| Optimization | Yes |
| Optimization Runs | `200` |
| Constructor Arguments (ABI-encoded) | `0x00000000000000000000000060b9262456de011f7d15a54cdd8c48baaa8b022f` |
| Source code | Paste the full contents of `flattened/BountybotRegistry.flattened.sol` (216 lines) |

Constructor argument = the single `address agentId_` parameter:
SPACE ID Agent ID contract `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`,
left-padded to 32 bytes. Verified with `cast abi-encode "f(address)" <addr>`.

## Flattened source

- File: `flattened/BountybotRegistry.flattened.sol` (216 lines)
- Produced by: `forge flatten src/BountybotRegistry.sol -o flattened/BountybotRegistry.flattened.sol`
- The original source has no imports (the `IAgentId` interface is defined
  inline), so the flattened file is the same contract with the flatten header.
  SPDX `MIT`, pragma `^0.8.24` — unchanged.

## Compile check (done 19 Nov 2026, before handover)

The flattened file was compiled in a clean temp project with the **identical**
settings (`solc 0.8.24`, optimizer on, runs 200, `via_ir` false):

```
forge build   → OK (only a pre-existing reentrancy lint note, same as the main build)
```

Runtime bytecode comparison vs the on-chain code (`cast code`, 12,095 bytes):

- Same length (6,046 bytes), same head, same `solc 0.8.24` metadata trailer.
- Differ in exactly 3 places, all expected for a flattened-source verification:
  1. Two 20-byte slots embed the immutable `agentId` value
     `60b9262456de011f7d15a54cdd8c48baaa8b022f` on-chain; the fresh compile has
     zeroes there (immutables are baked in at deploy time, not at compile time).
  2. The 32-byte IPFS metadata hash at the tail (it covers the source text,
     which differs between the original file and the flattened file).
- Everything else is byte-identical. BscScan accounts for both differences
  when verifying a flattened source with the constructor arguments above.

## After verification — checks

1. BscScan contract page shows the source + "Contract Source Code Verified".
2. Read `agentId()` on BscScan → must return
   `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.
3. Read `nextBountyId()` → `0` until the first demo bounty is posted
   (see `scripts/DEMO.md`).

## CLI alternative (blocked: no API key held)

```bash
forge verify-contract 0x32619eba3f351cb555355f6011c9e22782253867 \
  src/BountybotRegistry.sol:BountybotRegistry \
  --chain 56 \
  --constructor-args 0x00000000000000000000000060b9262456de011f7d15a54cdd8c48baaa8b022f \
  --compiler-version v0.8.24+commit.e11b9ed9 \
  --optimizer-runs 200 \
  --etherscan-api-key $BSCSCAN_API_KEY
```

Requires a BscScan API key — **not held**. Use the web form above instead.
