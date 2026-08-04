$$
\newcommand \TxTail {\mathrm{TxTail}}
\newcommand \Tx {\mathrm{Tx}}
\newcommand \ID {\mathrm{ID}}
\newcommand \Lease {\mathrm{Lease}}
\newcommand \FirstValid {\mathrm{FirstValid}}
\newcommand \LastValid {\mathrm{LastValid}}
\newcommand \LowWaterMark {\mathrm{LowWaterMark}}
\newcommand \FirstChecked {\mathrm{FirstChecked}}
\newcommand \LastChecked {\mathrm{LastChecked}}
\newcommand \RecentLeaseMap {\mathrm{RecentLeaseMap}}
\newcommand \LastValidMap {\mathrm{LastValidMap}}
$$

# Transaction Tail

The _Transaction Tail_ \\( \TxTail \\) is a data structure responsible for deduplication
and recent history lookups. It can be considered a rolling window of _recent_ transactions
and block headers observed in a reduced history of rounds, optimized for lookup
and retrieval.

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Transaction tail [reference implementation](https://github.com/algorand/go-algorand/blob/55011f93fddb181c643f8e3f3d3391b62832e7cd/ledger/txtail.go#L46).

It provides the following fields:

- `recentLeaseMap`\
A mapping of `round -> (TXLease -> round)` that saves the transaction `Lease` by
observation round, and the mapping uses `TXLease` as keys to store the `Lease` expiring
round.

- `blockHeaderData`\
Contains recent block header data. The expected availability range is `[Latest -
MaxTxnLife, Latest]`, allowing `MaxTxnLife + 1` rounds of lookback ( \\( 1001 \\)
with current parameters).

- `lastValidMap`\
A mapping of `round -> (txid -> uint16)` that enables the lookup of all transactions
expiring in a given round. For each round, the inner map stores `txid`s mapped to
16-bit unsigned integers representing the difference between the transaction’s `lastValid`
field and the round it was confirmed (`lastValid > confirmationRound` for all confirmed
transactions).

- `lowWaterMark`\
An unsigned 64-bit integer representing a round number such that for any transactions
where the `lastValid` field is `lastValid < lowWaterMark`, the node can quickly assert
that it is not present in the \\( \TxTail \\).

## Deduplication Check

A duplication check is the core functionality of \\( \TxTail \\).

```pseudocode
\begin{algorithm}
\caption{Check Duplicate}
\begin{algorithmic}
\Function{CheckDuplicate}{$\Tx_r, \FirstValid, \LastValid, \Tx_{\ID}, \Tx_{\Lease}$}
  \If{$\LastValid < \TxTail.\LowWaterMark$}
    \Return $\Tx_{\ID}$ is not in $\TxTail$
  \EndIf
  \If{$\Tx_{\Lease} \neq \emptyset$}
    \State $\FirstChecked \gets \FirstValid$
    \State $\LastChecked \gets \LastValid$
    \For{$r \in [\FirstChecked, \LastChecked]$}
      \If{$\Tx_{\Lease} \in \RecentLeaseMap(\Tx_r).\Lease \land r \leq \Tx_{\Lease}.\mathrm{Expiration}$}
        \Return $\Lease$ is a duplicate
      \EndIf
    \EndFor
  \EndIf
  \If{$\Tx_{\ID} \in \TxTail.\LastValidMap(\LastValid).\Tx_{\ID}$}
    \Return $\Tx_{\ID}$ is a duplicate transaction
  \EndIf
  \Return
\EndFunction
\end{algorithmic}
\end{algorithm}
```

The algorithm receives four fields of a transaction:

- The transaction round \\( \Tx_r \\),

- The transaction validity round fields \\( \FirstValid \\) and \\( \LastValid \\),

- The transaction identifier \\( \Tx_{\ID} \\),

- The transaction lease \\( \Tx_{\Lease} \\) (if set).

An early check is performed, where the \\( \LowWaterMark \\) field is used to quickly
discard transactions too far back in history and already purged from the \\( \ TxTail \\).

In case a \\( \Tx_{\Lease} \\) is set, the \\( \RecentLeaseMap \\) field is used
to deduplicate by \\( \Lease \\).

After checking for the \\( \Lease \\), the \\( \LastValidMap \\) is used and the
transaction is deduplicated through a lookup of \\( \Tx_{\ID} \\) by its \\( \LastValid \\)
round.

If the transaction is not found on the \\( \TxTail \\), the node can assume it is
not a duplicate, otherwise the validity interval would be too far back in the past
for the transaction to be confirmed anyway.
