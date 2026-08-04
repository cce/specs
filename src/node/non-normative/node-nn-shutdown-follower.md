$$
\newcommand \Node {\mathrm{node}}
\newcommand \FollowerNode {\mathrm{FollowerNode}}
\newcommand \Stop {\mathrm{Stop}}
\newcommand \Handlers {\mathrm{Handlers}}
\newcommand \Network {\mathrm{Network}}
\newcommand \Config {\mathrm{nodeConfig}}
\newcommand \Catchup {\mathrm{Catchup}}
\newcommand \Catchpoint {\mathrm{Catchpoint}}
\newcommand \Service {\mathrm{Service}}
\newcommand \Block {\mathrm{Block}}
\newcommand \Auth {\mathrm{Authenticator}}
\newcommand \CryptoPool {\mathrm{CryptoPool}}
$$

# Shutdown Follower Node

The following pseudocode describes how a node running in Follower Node mode is gracefully
shutdown.

The shutdown procedure ensures that all services are stopped and resources are properly
deallocated. This prevents data corruption and ensures the node stops in a stable
and predictable state.

```pseudocode
\begin{algorithm}
\caption{Follower Node Shutdown}
\begin{algorithmic}
\Function{FollowerNode.Stop}{}
  \State \Comment{Network Cleanup}
  \State $\Node.\Network.\Stop\Handlers()$
  \If{$\neg \Node.\Config.\Stop\Network$}
    \State $\Node.\Network.\Stop()$
  \EndIf
  \State \Comment{Service Shutdown}
  \If{$\exists \Node.\Catchpoint\Catchup\Service$}
    \State $\Node.\Catchpoint\Catchup\Service.\Stop()$
  \Else
    \State \Comment{Follower Services Only}
    \State $\Node.\Catchup\Service.\Stop()$
    \State $\Node.\Block\Service.\Stop()$
  \EndIf
  \State \Comment{Resource Cleanup}
  \State $\Node.\Catchup.\Block\Auth.\Stop()$
  \State $\Node.\CryptoPool.\mathrm{lowPriority}.\Stop()$
  \State $\Node.\CryptoPool.\Stop()$
\EndFunction
\end{algorithmic}
\end{algorithm}
```

> [!IMPORTANT]
> **IMPLEMENTATION:**
>
> Follower node shutdown [reference implementation](https://github.com/algorand/go-algorand/blob/df0613a04432494d0f437433dd1efd02481db838/node/follower_node.go#L211-L229).
