// Render fenced ```pseudocode blocks with pseudocode.js (vendored 2.4.1, see
// theme-ext/pseudocode.min.js).
//
// mdBook emits fenced blocks as <pre><code class="language-pseudocode">. Each
// block holds LaTeX algorithmic markup (the algpseudocode subset documented in
// src/CONTRIBUTIONS.md). The PDF build renders the same source natively via
// scripts/pdf-pseudocode.lua.
(function () {
    "use strict";

    var blocks = document.querySelectorAll("code.language-pseudocode");
    if (blocks.length === 0) {
        return;
    }

    // pseudocode.js picks its math backend (KaTeX or MathJax) at render time,
    // and this book loads MathJax async from the page head - so wait for it.
    function whenMathJaxReady(fn) {
        if (window.MathJax && window.MathJax.Hub) {
            fn();
        } else {
            setTimeout(function () {
                whenMathJaxReady(fn);
            }, 100);
        }
    }

    whenMathJaxReady(function () {
        // All DOM mutation must wait for MathJax's initial page pass to end:
        // replacing nodes while tex2jax scans the document invalidates its
        // captured element state and can wedge the typesetting queue (most
        // likely on the huge print.html page). The initial pass is also what
        // processes the page's \newcommand definition blocks, making the
        // macros available to the algorithm math typeset below. The "End"
        // hook runs immediately when MathJax is already past startup.
        window.MathJax.Hub.Register.StartupHook("End", function () {
            var rendered = [];
            Array.prototype.forEach.call(blocks, function (code) {
                var pre = code.parentElement;
                var container = document.createElement("div");
                container.className = "pseudocode-block";
                try {
                    window.pseudocode.render(code.textContent, container, {
                        lineNumber: true,
                    });
                } catch (err) {
                    // Leave the source block visible so the error is diagnosable.
                    console.error("pseudocode.js failed to render a block:", err);
                    return;
                }
                pre.parentNode.replaceChild(container, pre);
                // With a MathJax 2.x backend pseudocode.js leaves math as
                // $...$ text; rewrite to the \( ... \) delimiters this book's
                // MathJax processes.
                container.innerHTML = container.innerHTML.replace(
                    /\$([^$]+)\$/g,
                    "\\($1\\)"
                );
                rendered.push(container);
            });

            rendered.forEach(function (el) {
                window.MathJax.Hub.Queue(["Typeset", window.MathJax.Hub, el]);
            });
        });
    });
})();
