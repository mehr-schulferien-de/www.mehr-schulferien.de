module.exports = {
  content: [
    './js/**/*.js',
    '../lib/mehr_schulferien_web/**/*.*ex',
    '../lib/mehr_schulferien_web/**/*.heex',
    '../lib/mehr_schulferien_web.ex',
    '../lib/mehr_schulferien_web/**/*.html.heex',
    '../lib/mehr_schulferien_web/**/*.html.eex'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  safelist: [
    // Day type colors that might be dynamically generated
    {
      pattern: /^bg-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/
    },
    {
      pattern: /^text-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/
    },
    {
      pattern: /^border-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/
    },
    // Grid classes that might be generated
    {
      pattern: /^grid-cols-/
    },
    {
      pattern: /^col-span-/
    },
  ]
} 