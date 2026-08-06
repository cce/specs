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
    var MATHJAX_POLL_MS = 100;
    var MATHJAX_WAIT_MS = 30000;

    function whenMathJaxReady(fn, waited) {
        waited = waited || 0;
        if (window.MathJax && window.MathJax.Hub) {
            fn();
        } else if (waited < MATHJAX_WAIT_MS) {
            setTimeout(function () {
                whenMathJaxReady(fn, waited + MATHJAX_POLL_MS);
            }, MATHJAX_POLL_MS);
        } else {
            console.warn(
                "pseudocode-init: MathJax did not load; " +
                "pseudocode blocks are left unrendered."
            );
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
                // MathJax processes. Rewrite per text node (not innerHTML) so
                // a stray unpaired $ cannot pair across element boundaries
                // and swallow markup into the math delimiters.
                var walker = document.createTreeWalker(
                    container,
                    NodeFilter.SHOW_TEXT
                );
                var text;
                while ((text = walker.nextNode())) {
                    if (text.nodeValue.indexOf("$") !== -1) {
                        text.nodeValue = text.nodeValue.replace(
                            /\$([^$]+)\$/g,
                            "\\($1\\)"
                        );
                    }
                }
                // Unnumbered captions: pseudocode.js hardcodes "Algorithm N".
                var caption = container.querySelector(
                    ".ps-algorithm > .ps-line > .ps-keyword"
                );
                if (caption && /^Algorithm \d+\s*$/.test(caption.textContent)) {
                    caption.textContent = "Algorithm: ";
                }
                rendered.push(container);
            });

            rendered.forEach(function (el) {
                window.MathJax.Hub.Queue(["Typeset", window.MathJax.Hub, el]);
            });
        });
    });
})();
