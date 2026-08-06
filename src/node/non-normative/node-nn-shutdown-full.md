$$
\newcommand \Node {\mathrm{node}}
\newcommand \FullNode {\mathrm{FullNode}}
\newcommand \Network {\mathrm{Network}}
\newcommand \Stop {\mathrm{Stop}}
\newcommand \Close {\mathrm{Close}}
\newcommand \Config {\mathrm{nodeConfig}}
\newcommand \Catchup {\mathrm{Catchup}}
\newcommand \Service {\mathrm{Service}}
\newcommand \Ledger {\mathrm{Ledger}}
\newcommand \AccountManager {\mathrm{AccountManager}}
\newcommand \Registry {\mathrm{Registry}}
\newcommand \TP {\mathrm{TxPool}}
\newcommand \Handler {\mathrm{Handler}}
\newcommand \Handlers {\mathrm{Handlers}}
\newcommand \Catchpoint {\mathrm{Catchpoint}}
$$

# Shutdown Full Node

The pseudocode below outlines how a Full Node is gracefully shut down.

This process ensures all services are stopped, garbage collection is performed,
resources are released, and the internal state is properly cleaned up.

By following this structured approach, the node avoids corrupting data or leaving
the Algorand network in an inconsistent state, which is critical for maintaining
the integrity of the system.

```pseudocode
\begin{algorithm}
\caption{Full Node Shutdown}
\begin{algorithmic}
\Function{FullNode.Stop}{}
  \State \Comment{Network Cleanup}
  \State $\Node.\Network.\Stop\Handlers()$
  \State $\Node.\Network.\Stop\mathrm{Validator}\Handlers()$
  \If{$\neg \Node.\Config.\Stop\Network$}
    \State $\Node.\Network.\Stop()$
  \EndIf
  \State \Comment{Service Shutdown}
  \If{$\exists \Node.\Catchpoint\Catchup\Service$}
    \State $\Node.\Catchpoint\Catchup\Service.\Stop()$
  \Else
    \State \Comment{Full Node Services}
    \State $\Node.\Stop\mathrm{AllServices}()$
  \EndIf
  \State \Comment{Resource Cleanup}
  \State $\Node.\TP.\Stop()$
  \State \Comment{Final Cleanup}
  \State $\Node.\Ledger.\Close()$
  \State \Comment{Post-Shutdown Cleanup}
  \State $\mathrm{WaitMonitoringRoutines}()$
  \State $\Node.\AccountManager.\Registry.\Close()$
  \For{$\Handler \in \Node.\mathrm{Database}\Handlers$}
    \State $\Handler.\Close()$
  \EndFor
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Full node shutdown [reference implementation](https://github.com/algorand/go-algorand/blob/e60d3ddd1d63e60f32bda6935554b34fdb0e1515/node/node.go#L444-L487).

This structured shutdown process helps ensure that Full Nodes exit cleanly, preserving
correctness, avoiding data leaks, and minimizing node and network risk.
