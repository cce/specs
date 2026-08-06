$$
\newcommand \RootDir {\mathrm{rootDir}}
\newcommand \Config {\mathrm{nodeConfig}}
\newcommand \Phonebook {\mathrm{phonebookAddrs}}
\newcommand \GenesisBlock {\mathrm{genesisBlock}}
\newcommand \Node {\mathrm{node}}
\newcommand \FullNode {\mathrm{FullNode}}
\newcommand \Logger {\mathrm{Logger}}
\newcommand \Hash {\mathrm{Hash}}
\newcommand \Network {\mathrm{Network}}
\newcommand \WS {\mathrm{WS}}
\newcommand \PtoP {\mathrm{P2P}}
\newcommand \HYB {\mathrm{HYB}}
\newcommand \Peer {\mathrm{Peer}}
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
\newcommand \Service {\mathrm{Service}}
\newcommand \Create {\mathrm{Create}}
$$

# Initialize Full Node

The `algod` Full Node is responsible for:

- **Validating and propagating** transactions and blocks,

- **Maintaining the blockchain state**, either fully (_Archival_) or partially (_Non
Archival_), as defined in the [Ledger](../../ledger/ledger-overview.md),

- **Participating in the consensus protocol**, as outlined in the [ABFT specification](../../abft/abft.md).

## Initialization

The pseudocode below outlines the main steps involved when initializing an `algod`
_Full Node_:

```pseudocode
\begin{algorithm}
\caption{Full Node Initialization}
\begin{algorithmic}
\Function{FullNode.Start}{$\RootDir, \Config, \Phonebook, \GenesisBlock$}
  \State $\Node \gets {\textbf{new }} \FullNode$
  \State $\Node.\mathrm{log} \gets \Logger(\Config)$
  \State $\Node.\GenesisBlock.\mathrm{ID} \gets \GenesisBlock.\mathrm{ID}()$
  \State $\Node.\GenesisBlock.\Hash \gets \GenesisBlock.\Hash()$
  \State \Comment{Network Initialization}
  \If{$\Config.\mathrm{EnableHybridMode}$}
    \State $\Node.\Network \gets \Create\HYB\Network(\Phonebook)$
  \ElsIf{$\Config.\mathrm{EnableP2P}$}
    \State $\Node.\Network \gets \Create\PtoP\Network(\Phonebook)$
  \Else
    \State $\Node.\Network \gets \Create\WS\Network(\Phonebook)$
  \EndIf
  \State \Comment{Crypto Resource Pools Initialization}
  \State $\Node.\CryptoPool \gets \Create\mathrm{ExecutionPool}()$
  \State $\Node.\CryptoPool.\mathrm{lowPriority} \gets \Create\mathrm{BacklogPool()}$
  \State $\Node.\CryptoPool.\mathrm{highPriority} \gets \Create\mathrm{BacklogPool()}$
  \State \Comment{Ledger Initialization}
  \State $\mathrm{ledgerPaths} \gets \mathrm{ResolvePaths}(\RootDir, \Config)$
  \State $\Node.\Ledger \gets \mathrm{LoadLedger}(\mathrm{ledgerPaths}, \GenesisBlock)$
  \State \Comment{Account Management}
  \State $\Registry \gets \mathrm{ParticipationRegistry}()$
  \State $\Node.\AccountManager \gets \Create\AccountManager(\Registry)$
  \State $\mathrm{LoadParticipationKeys}(\Node)$
  \State \Comment{Transaction Pool Initialization}
  \State $\Node.\TP \gets \Create\TP(\Node.\Ledger)$
  \State $\mathrm{RegisterBlockListeners}(\Node.\TP)$
  \State \Comment{Services Initialization}
  \State $\Node.\Block\Service \gets \Create\Block\Service()$
  \State $\Node.\Ledger\Service \gets \Create\Ledger\Service()$
  \State $\Node.\TP\Service \gets \Create\TP\mathrm{Syncer}()$
  \State $\Node.\Agreement\Service \gets \Create\Agreement\Service()$
  \State $\Node.\Catchup\Service \gets \Create\Catchup\Service()$
  \State $\Node.\StateProofService \gets \Create\StateProofService()$
  \State $\Node.\HeartbeatService \gets \Create\HeartbeatService()$
  \Return $\Node$
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Full Node initialization [reference implementation](https://github.com/algorand/go-algorand/blob/e60d3ddd1d63e60f32bda6935554b34fdb0e1515/node/node.go#L184-L347).

### Network

The _network layer_ is set up depending on the configuration:

- \\( \WS \\) (WebSocket) for the Relay Network setups,

- \\( \PtoP \\) for Peer-to-Peer Network, or

- \\( \HYB \\) for the \\( \PtoP \\)-\\( \WS \\) Hybrid Network, for nodes operating
in a unified network layer.

The network layer manages:

- \\( \Peer \\) discovery using _phonebook addresses_,

- Connection pools, and

- Message routing.

> [!NOTE]
> For further details on the network layer, refer to Algorand Network [non-normative specification](../../network/network-overview.md).

### Cryptography Resource Pools

The node initializes worker pools for handling cryptographic tasks with priority
queues:

- \\( \CryptoPool \\) handles general-purpose cryptographic operations,

- \\( \CryptoPool.\mathrm{lowPriority} \\) and \\( \CryptoPool.\mathrm{highPriority} \\)
handle transaction verification, grouped by priority.

> [!NOTE]
> For further details on the transaction validation, see the Ledger [specification](../../ledger/ledger-overview.md).

> [!NOTE]
> For further details on the cryptographic primitives and algorithms, see the Crypto [specification](../../crypto/crypto.md).

### Ledger

The node loads its local view of the blockchain state from disk (accounts, blocks, protocol data, etc.),
based on the specified genesis configuration.

If the Ledger is empty, it initializes the required structures.

It also validates:

- The genesis configuration, and

- Ledger integrity.

> [!NOTE]
> For further details on the Ledger entities, see the Ledger [specification](../../ledger/ledger-overview.md).

### Account Management (Agreement)

The node prepares for consensus participation and registered account tracking by:

- Creating and managing a registry of participation keys,

- Loading any pre-existing participation keys from disk,

- Setting up participation key rotation.

> [!NOTE]
> For further details on the Algorand keys, see the Keys [specification](../../keys/keys-overview.md).

> [!NOTE]
> For further details on the key registration transactions, see the Ledger [specification](../../ledger/ledger-overview.md).

### Transaction Pool

The node creates the _Transaction Pool_ (\\( \TP \\)), which:

- Accepts and validates new transactions,

- Maintains the queue of uncommitted transactions,

- Manages transaction synchronization across the network,

- Creates Block Listeners reacting to new blocks to prune already committed transactions
and update pending transactions.

> [!NOTE]
> For further details on the Transaction Pool, see the Ledger [non-normative specification](../../ledger/non-normative/ledger-nn-txpool.md).

### Services

Finally, the node launches all essential background services:

<!-- TODO: Fix links once all chapters are finalized -->

- [Catchup](./node-nn-sync.md) Service,

- [Agreement](../../abft/abft.md) Service,

- [Transaction Pool](../../ledger/non-normative/ledger-nn-txpool.md) Syncer Service,

- [Block](../../ledger/ledger-block.md) Service,

- [Ledger](../../ledger/ledger.md) Service,

- [Transaction](../../ledger/ledger-transactions.md) Handler,

- [State Proof](../../crypto/crypto-state-proofs.md) Worker.

- [Heartbeat](../../ledger/ledger-txn-heartbeat.md) Service.
