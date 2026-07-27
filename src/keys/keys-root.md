# Root Keys

Root keys are used to identify ownership of an account. An Algorand node only
interacts with the public part of a root key (public keys or program bytecode).

An account is controlled by one of the following _root_ authorization methods, which
also bind the account address to the authorization material:

- A single [Ed25519](../crypto/crypto-ed25519.md) key pair. The public key of the
root key is used directly as the account address;

- A [multisignature](../ledger/ledger-txn-authorization.md#multisignature) composition
of Ed25519 key pairs. The account address is derived by hashing the multisignature
version, the authorization threshold, and all the participating public keys;

- A [logic signature](../avm/avm-mode-logic-signatures.md#contract-account-mode)
program, wholly in charge of a _contract account_. The account address is derived
by hashing the program bytecode;

- A [post-quantum scheme](../ledger/ledger-txn-authorization.md#post-quantum-signature)
key pair. The account address is derived by hashing the scheme identifier, an address
salt, and the public key.

{{#include ../_include/styles.md:note}}
> Application accounts are the exception: their address is the hash of the Application
> ID (prefixed by `appID`), which binds no authorization material. No root key exists
> for these accounts: they cannot authorize top-level transactions and, unless rekeyed,
> are controlled exclusively by their Application through [inner transactions](../avm/avm-ops-inner-transactions.md).

Regardless of the authorization method, root keys are used to authorize transaction
messages as well as delegating the voting authentication using _voting keys_, unless
that specific account was rekeyed. A rekeyed account would use the rekeyed key in
lieu of the root key.

A relationship between a _root key_ and _voting keys_ is established when accounts
_register_ their participation in the agreement protocol.

> For further details on the key registration (`keyreg`) process, refer to Ledger
> [specification](../ledger/ledger-transactions.md).
