const fs = require('fs');
const { marked } = require('marked');

const md = fs.readFileSync('Project_Documentation.md', 'utf8');
const body = marked.parse(md);

const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Spring Boot Library Management — Project Documentation</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&family=Fira+Code:wght@400;500&display=swap');
  *, *::before, *::after { box-sizing: border-box; }
  body { font-family: 'Inter', sans-serif; color: #1a1a2e; background: #fff; margin: 0; padding: 40px 60px; line-height: 1.7; font-size: 14px; }
  h1 { font-size: 28px; color: #0f3460; border-bottom: 3px solid #3498db; padding-bottom: 8px; margin-top: 30px; }
  h2 { font-size: 22px; color: #16213e; border-bottom: 2px solid #e0e0e0; padding-bottom: 6px; margin-top: 36px; }
  h3 { font-size: 17px; color: #1a1a2e; margin-top: 24px; }
  h4 { font-size: 15px; color: #333; margin-top: 18px; }
  hr { border: none; border-top: 1px solid #ddd; margin: 30px 0; }
  table { width: 100%; border-collapse: collapse; margin: 16px 0; font-size: 13px; }
  th, td { border: 1px solid #ccc; padding: 8px 12px; text-align: left; }
  th { background: #ecf0f1; font-weight: 600; }
  pre { background: #f5f7fa; border: 1px solid #ddd; border-radius: 6px; padding: 14px 18px; overflow-x: auto; font-size: 12.5px; line-height: 1.5; }
  code { font-family: 'Fira Code', monospace; font-size: 12.5px; }
  p code, li code { background: #f0f0f0; padding: 1px 5px; border-radius: 3px; }
  ul, ol { padding-left: 24px; }
  li { margin-bottom: 4px; }
  strong { color: #0f3460; }
  a { color: #2980b9; }
  img { max-width: 100%; border: 1px solid #ccc; border-radius: 4px; margin: 10px 0; }

  @media print {
    body { padding: 20px 30px; font-size: 12px; }
    pre { font-size: 11px; padding: 10px; page-break-inside: avoid; }
    h1, h2, h3 { page-break-after: avoid; }
    table { page-break-inside: avoid; }
    hr { page-break-after: avoid; }
  }
</style>
</head>
<body>
${body}
</body>
</html>`;

fs.writeFileSync('Project_Documentation.html', html, 'utf8');
console.log('Done! Created Project_Documentation.html');
