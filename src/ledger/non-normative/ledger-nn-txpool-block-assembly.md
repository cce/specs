$$
\newcommand \TP {\mathrm{TxPool}}
\newcommand \AD {\mathrm{assemblyDeadline}}
\newcommand \AW {\mathrm{assemblyWait}}
\newcommand \AssembleBlock {\mathrm{AssembleBlock}}
\newcommand \BlockEval {\mathrm{BlockEvaluator}}
\newcommand \EB {\mathrm{emptyBlock}}
\newcommand \rnd {\mathrm{round}}
\newcommand \nil {\mathit{nil}}
$$

# Block Assembly

The \\( \TP \\) is responsible for populating the `payset` of a block, a process
referred to as `BlockAssembly`.

The `BlockAssembly` is a time-bound algorithm that manages the flow of transactions
into the pending \\( \BlockEval \\) and stops ingestion once timing constraints are
reached.

It also handles possible desynchronizations between the \\( \TP.\rnd \\) (the current
round as perceived by the \\( \TP \\)) and the actual round being assembled by the
pending \\( \BlockEval \\). This discrepancy arises based on how often the `Update`
function has been invoked.

The following pseudocode outlines a high-level view of how `BlockAssembly` operates:

```pseudocode
\begin{algorithm}
\caption{Block Assembly}
\begin{algorithmic}
\Function{AssembleBlock}{$r$}
  \If{$\TP.\rnd < r - 2$}
    \Return $\AssembleBlock.\EB(r)$
  \EndIf
  \If{$r < \TP.\rnd$}
    \Return $\nil$
  \EndIf
  \State $\AD \gets \rnd.\mathrm{startTime}() + \delta_{\AD}$
  \State wait until $\AD \lor (\TP.\rnd = r \land \BlockEval \text{ is done})$
  \If{$\lnot \BlockEval.\mathrm{done}()$}
    \If{$\TP.\rnd > r$}
      \Return $\nil$ \Comment{$r$ is behind $\TP.\rnd$}
    \EndIf
    \State $\AD \gets \AD + \epsilon_{\AW}$
    \State wait until $\AD \lor (\TP.\rnd = r \land \BlockEval \text{ is done})$
    \If{$\lnot \BlockEval.\mathrm{done}()$}
      \Return $\AssembleBlock.\EB(r)$ \Comment{Ran out of time}
    \EndIf
    \If{$\TP.\rnd > r$}
      \Return $\nil$ \Comment{Requested round is behind transaction pool round}
    \ElsIf{$\TP.\rnd = r - 1$}
      \Return $\AssembleBlock.\EB(r)$
    \ElsIf{$\TP.\rnd < r$}
      \Return $\nil$
    \EndIf
  \EndIf
  \Return $\BlockEval.\mathrm{block}$
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Block assembly [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/data/pools/transactionPool.go#L860).

This algorithm begins by taking a target round \\( r \\), for which a new block
is to be assembled.

It first checks the round currently perceived by the \\( \TP \\), which matches the
round being handled by the pending \\( \BlockEval \\).

- If the \\( \TP.\rnd \\) is significantly behind \\( r \\): an _empty block_ is immediately
assembled and returned, as there’s no time to catch up.

- If the \\( \TP \\) is already ahead of \\( r \\): no action is needed, as \\( \TP \\)
is simply ahead of the network’s current state.

Next, the algorithm waits for the assembly deadline \\( \delta_{\AD} \\). During
this time, the pending \\( \BlockEval \\) is expected to notify the completed block
assembly in the background via the `Ingestion` function, and that it is caught
up to the round \\( r \\).

If this doesn’t happen by the deadline, the algorithm performs another round of checks:

- If the \\( \TP.\rnd \\) is now ahead of \\( r \\): the process is aborted, waiting
for the network to catch up. This should rarely happen.

- Othwewise, if the \\( \TP \\) is still behind: an additional wait period \\( \epsilon_{\AW} \\)
is introduced.

After this extra wait, similar checks are repeated:

- If the \\( \TP \\) is still too far behind: there is no more time to wait, and
the algorithm exits.

- Otherwise: the algorithm proceeds.

If all checks pass and timing constraints are met without returning early (an _empty
block_ or a \\( \nil \\) value), the pending \\( \BlockEval \\) finally provides
the fully _assembled block_ for round \\( r \\).
