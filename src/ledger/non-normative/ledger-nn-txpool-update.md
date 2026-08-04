$$
\newcommand \TP {\mathrm{TxPool}}
\newcommand \NB {\mathrm{newBlock}}
\newcommand \SD {\mathrm{stateDelta}}
\newcommand \FeeMul {\mathrm{feeThresholdMultiplier}}
\newcommand \FeeExp {\mathrm{expFeeFactor}}
\newcommand \PendingFB {\mathrm{pendingFullBlocks}}
\newcommand \Update {\mathrm{Update}}
$$

# Update

The `Update` function is called each time a new block is confirmed.

During this process, the \\( \TP \\) removes all transactions that have either already
been committed or whose `lastValid` field has expired.

The adjustment of the fee prioritization mechanism depends on how many full blocks
are currently pending in the \\( \TP_{pq} \\) queue.

The state of the \\( \TP \\) is then updated as follows:

```pseudocode
\begin{algorithm}
\caption{Update $\TP$}
\begin{algorithmic}
\Function{Update}{$\NB\ b, \SD\ sd$}
  \If{$\TP_{pq}$ is empty or outdated}
    \If{$\TP.\PendingFB = 0$}
      \State $\FeeMul \gets \frac{FeeMul}{FeeExp}$
    \ElsIf{$\TP.\PendingFB = 1$}
      \State \Comment{Intentionally left blank to maintain the value of $\FeeMul$}
    \Else
      \If{$\FeeMul = 0$}
        \State $\FeeMul \gets 1$
      \Else
        \State $\FeeMul \gets \FeeMul \cdot \FeeExp$
      \EndIf
    \EndIf
  \EndIf
  \State $\TP.\mathrm{Prune}(b, sd)$
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Update on a new block [reference implementation](https://github.com/algorand/go-algorand/blob/b6e5bcadf0ad3861d4805c51cbf3f695c38a93b7/data/pools/transactionPool.go#L532).

The algorithm above updates the \\( \FeeMul \\) based on the current state of the
pending queue. Specifically, it checks whether the queue is either empty (no leftover
transactions from the previous block assembly) or outdated (i.e., the remaining
transactions were grouped into full blocks from a round \\( r_p \\) such that
\\( r \geq r_p \\), where \\( r \\) is the current round).

The adjustment logic works as follows:

- If there are \\( 0 \\) pending full blocks:\
This suggests that any previous congestion has cleared. The \\( \FeeMul \\) is reduced
by dividing it by the \\( \FeeExp \\). If this low-congestion state continues, the
multiplier quickly diminishes and approaches \\( 0 \\).

- If there is exactly \\( 1 \\) pending full block:\
The \\( \FeeMul \\) remains unchanged.

- Otherwise, if there are more than \\( 1 \\) pending full block (\\( \TP.\PendingFB > 1 \\)):

  - If the \\( \FeeMul \\) is currently \\( 0 \\), it is set to \\( 1 \\) to reflect
  a sudden spike in congestion.

  - If it already has a value, it is multiplied by the \\( \FeeExp \\), causing it
  to grow in response to continued congestion.

After updating the fee prioritization mechanism, the \\( \TP \\) is pruned by removing:

- Transactions that were included in the newly committed block \\( b \\), and

- Transactions whose `lastValid` field is less than the current round \\( r \\)
(which matches the round of \\( b \\) that was just observed).
