{{#include ../_include/tex-macros/domain-separators.md}}

# Domain Separation

Before an object is input to some cryptographic function, it is prepended with a
multi-character domain-separating prefix.

All domain separators must be “prefix-free” (that is, they must not be concatenated).

The list below specifies each `prefix`:

- For cryptographic primitives:
  - \\( \\Domain{OT1} \\) and \\( \\Domain{OT2} \\): The first and second layers of keys used for [ephemeral signatures](../keys/keys-ephemeral.md).
  - \\( \\Domain{MA} \\): An internal node in a [Merkle tree](./crypto-merkle-tree.md).
  - \\( \\Domain{MB} \\): A bottom leaf in a [vector commitment](./crypto-vector-commitment.md).
  - \\( \\Domain{KP} \\): Is a public key used by the [Merkle Signature Scheme](../keys/keys.md)
  - \\( \\Domain{spc} \\): A coin used as part of the state proofs construction.
  - \\( \\Domain{spp} \\): Participant’s information (state proof public key and weight) used for state proofs.
  - \\( \\Domain{sps} \\): A signature from a specific participant used for state proofs.

- In the [Algorand Ledger](../ledger/ledger.md):
  - \\( \\Domain{BH} \\): A _Block Header_.
  - \\( \\Domain{BR} \\): A _Balance Record_.
  - \\( \\Domain{GE} \\): A _Genesis_ configuration.
  - \\( \\Domain{MsigProgram} \\): A logic signature program delegation by a
  [multisignature account](../avm/avm-mode-logic-signatures.md#delegated-signature-mode)
  (the delegating account address concatenated with the program bytecode).
  - \\( \\Domain{PQA} \\): A [_post-quantum account address_](../ledger/ledger-txn-authorization.md#post-quantum-signature).
  - \\( \\Domain{PQProgram} \\): A logic signature program delegation by a
  [post-quantum account](../ledger/ledger-txn-authorization.md#logic-signature-delegation)
  (the delegating account address concatenated with the program bytecode).
  - \\( \\Domain{spm} \\): A _State Proof_ message.
  - \\( \\Domain{STIB} \\): A _SignedTxnInBlock_ that appears as part of the leaf in the Merkle
  tree of transactions.
  - \\( \\Domain{TG} \\): A [_Transaction Group_](../ledger/ledger-txn-groups.md).
  - \\( \\Domain{TL} \\): A leaf in the Merkle tree of transactions.
  - \\( \\Domain{TX} \\): A _Transaction_.
  - \\( \\Domain{SpecialAddr} \\): A prefix used to generate designated addresses for specific functions,
  such as sending state proof transactions.

- In the [Algorand Byzantine Fault Tolerance protocol](../abft/abft.md):
  - \\( \\Domain{AS} \\): An _Agreement Selector_, which is also a VRF input.
  - \\( \\Domain{CR} \\): A _Credential_.
  - \\( \\Domain{SD} \\): A _Seed_.
  - \\( \\Domain{PL} \\): A _Payload_.
  - \\( \\Domain{PS} \\): A _Proposer Seed_.
  - \\( \\Domain{VO} \\): A _Vote_.

- In other places:
  - \\( \\Domain{arc} \\): ARCs-related hashes <https://github.com/algorandfoundation/ARCs>. The
  prefix for ARC-XXXX should start with \\( \\Domain{arcXXXX} \\) (where \\( \\Domain{XXXX} \\) is the 0-padded
  number of the ARC). For example, ARC-0003 can use any prefix starting with \\( \\Domain{arc0003} \\).
  - \\( \\Domain{MX} \\): An arbitrary message used to prove ownership of a cryptographic secret.
  - \\( \\Domain{NPR} \\): A message that proves a peer’s stake in an Algorand networking implementation.
  - \\( \\Domain{PQK} \\): The derivation of a post-quantum signing key seed from master entropy
  (used by key management tools).
  - \\( \\Domain{TE} \\): An arbitrary message reserved for testing purposes.
  - \\( \\Domain{Program} \\): A TEAL bytecode program.
  - \\( \\Domain{ProgData} \\): Data that is signed within TEAL bytecode programs.

> [!NOTE]
> Auctions are deprecated; however, their prefixes are still reserved in code:
>
> - \\( \\Domain{aB} \\): A _Bid_.
> - \\( \\Domain{aD} \\): A _Deposit_.
> - \\( \\Domain{aO} \\): An _Outcome_.
> - \\( \\Domain{aP} \\): Auction parameters.
> - \\( \\Domain{aS} \\): A _Settlement_.
