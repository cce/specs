const mermaidDarkMode = document.documentElement.classList.contains('dark');
const mermaidDarkCSS = mermaidDarkMode
    ? '.lineWrapper line, marker path { stroke: #d1d5db !important; } marker path { fill: #d1d5db !important; }'
    : '';

mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    themeCSS: `.eventWrapper { filter: none !important; } ${mermaidDarkCSS}`,
    themeVariables: {
        fontFamily: 'Noto Sans, sans-serif',
        fontSize: '18px',
        lineColor: mermaidDarkMode ? '#d1d5db' : '#374151',
        primaryTextColor: '#111827',
        secondaryTextColor: '#111827',
        tertiaryTextColor: '#111827',
        textColor: mermaidDarkMode ? '#e5e7eb' : '#111827',
    },
});

for (const theme of ['light', 'dark']) {
    document.getElementById(`mdbook-theme-${theme}`)?.addEventListener('click', () => window.location.reload());
}
