$$
\newcommand \disable {\textbf{disable }}
\newcommand \RootDir {\mathrm{rootDir}}
\newcommand \Config {\mathrm{nodeConfig}}
\newcommand \Phonebook {\mathrm{phonebookAddrs}}
\newcommand \GenesisBlock {\mathrm{genesisBlock}}
\newcommand \Node {\mathrm{node}}
\newcommand \FollowerNode {\mathrm{FollowerNode}}
\newcommand \Logger {\mathrm{Logger}}
\newcommand \Hash {\mathrm{Hash}}
\newcommand \Network {\mathrm{Network}}
\newcommand \WS {\mathrm{WS}}
\newcommand \CryptoPool {\mathrm{CryptoPool}}
\newcommand \Registry {\mathrm{Registry}}
\newcommand \Ledger {\mathrm{Ledger}}
\newcommand \Block {\mathrm{Block}}
\newcommand \Agreement {\mathrm{Agreement}}
\newcommand \AccountManager {\mathrm{AccountManager}}
\newcommand \StateProofService {\mathrm{StateProofService}}
\newcommand \HeartbeatService {\mathrm{HeartbeatService}}
\newcommand \TP {\mathrm{TxPool}}
\newcommand \Catchup {\mathrm{Catchup}}
\newcommand \Auth {\mathrm{Authenticator}}
\newcommand \Service {\mathrm{Service}}
\newcommand \Create {\mathrm{Create}}
$$

# Initialize Follower Node

Unlike a _Full Node_, a _Follower Node_ is a lightweight type of Algorand node designed
primarily for data access, not participation in consensus or transaction validation.

Key characteristics:

- It may not participate in the consensus protocol.

- It may not maintain a _Transaction Pool_.

- Its main function is to stay synchronized with the blockchain, keeping an up-to-date
copy of Ledger and block data.

- It is designed to pause and wait for connected applications (e.g., indexers, explorers,
or analytics tools) to finish processing the data it provides.

These nodes are ideal for read-heavy infrastructure, such as block explorers or
services that require continuous blockchain observation and access to its data but
don’t contribute to block validation or propagation.

## Initialization

The pseudocode below outlines the main steps involved when initializing an `algod`
_Follower Node_:

```pseudocode
\begin{algorithm}
\caption{Follower Node Initialization}
\begin{algorithmic}
\Function{FollowerNode.Start}{$\RootDir, \Config, \Phonebook, \GenesisBlock$}
  \State $\Node \gets {\textbf{new }} \FollowerNode$
  \State $\Node.\mathrm{log} \gets \Logger(\Config)$
  \State $\Node.\GenesisBlock.\mathrm{ID} \gets \GenesisBlock.\mathrm{ID}()$
  \State $\Node.\GenesisBlock.\mathrm{ID} \gets \GenesisBlock.\Hash()$
  \State \Comment{Network Initialization - WebSocket Only}
  \State $\Node.\Network \gets \Create\WS\Network(\Phonebook)$
  \State $\Node.\Network.\mathrm{DeregisterMessageInterest}(\texttt{AgreementVoteTag}, \texttt{ProposalPayloadTag}, \texttt{VoteBundleTag})$
  \State \Comment{Crypto Resource Pools Initialization - Minimal}
  \State $\Node.\CryptoPool \gets \Create\mathrm{ExecutionPool}()$
  \State $\Node.\CryptoPool.\mathrm{lowPriority} \gets \Create\mathrm{BacklogPool()}$
  \State \Comment{Ledger Initialization}
  \State $\mathrm{ledgerPaths} \gets \mathrm{ResolvePaths}(\RootDir, \Config)$
  \State $\Node.\Ledger \gets \mathrm{LoadLedger}(\mathrm{ledgerPaths}, \GenesisBlock)$
  \State \Comment{Service Components - Limited}
  \State $\Node.\Block\Service \gets \Create\Block\Service()$
  \State $\Node.\Catchup\Service \gets \Create\Catchup\Service()$
  \State $\Node.\Catchup\Block\Auth \gets \Create\Block\Auth()$
  \State \Comment{Transaction Handling - Simulation Only}
  \State $\disable \mathrm{TxBroadcast}()$
  \State $\disable \TP()$
  \State \Comment{Agreement - All Disabled}
  \State $\disable \AccountManager()$
  \State $\disable \Agreement()$
  \State $\disable \StateProofService()$
  \State $\disable \HeartbeatService()$
  \State $\mathrm{SetSyncRound}(\Node.\Ledger.\mathrm{LatestTrackerCommittedRound}() + 1)$
  \If{$\mathrm{InCatchpointCatchupState}()$}
    \State $\mathrm{InitializeCatchpointCatchup}()$
  \EndIf
  \Return $\Node$
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Follower Node initialization [reference implementation](https://github.com/algorand/go-algorand/blob/df0613a04432494d0f437433dd1efd02481db838/node/follower_node.go#L79-L158).

Compared to a [_Full Node_](node-nn-init-full.md), a _Follower Node_ is significantly
lighter in functionality and system demands.

Below are the main differences.

### Networking

Unlike Full Nodes, which support multiple network layer options (such as standard
Peer-to-Peer and Hybrid Networks), Follower Nodes operate only in \\( \WS \\) mode.
This simplifies peer communication but limits participation to passive synchronization.

### Cryptography Resource Pools

A Follower Node initializes only one low-priority cryptographic verification pool.
This minimal setup is enough for passive data validation without handling transaction
traffic or cryptographic voting.

### Ledger

Follower Nodes expose a specialized API to retrieve Ledger cache data, used by
external services to index, analyze, or react to blockchain events without interfering
with node operation.

For more on this functionality, refer to the Algorand External Systems Overview.

### Account Management (Agreement)

The Follower Node does not broadcast transactions and does not participate in consensus.
It is read-only and does not propose, vote on, or validate blocks.

### Services

Only two core services are active:

- **Catchup Service**: Keeps the node synchronized with the latest blockchain state.

- **Block Service**: Allows the node to retrieve and serve block data to external
consumers. It allows external services (e.g., indexers or applications) to query
and react to new blocks as they arrive.

### Synchronization and Catchup

Despite its limited role, a Follower Node still maintains full Catchup capabilities,
allowing it to fast-forward to the latest state using checkpoint data.

### Wait-for-Ingestion

This operative mode allows the node to pause block progression until external data
consumers (such as indexers or analytics tools) have finished ingesting the current
block. This ensures data consistency across services that rely on up-to-date chain
data.
