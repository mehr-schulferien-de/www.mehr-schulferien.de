module.exports = {
  darkMode: 'media',
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
    // Dark mode variants need to be explicitly included
    'dark:bg-gray-50', 'dark:bg-gray-100', 'dark:bg-gray-700', 'dark:bg-gray-800', 'dark:bg-gray-900',
    'dark:text-gray-100', 'dark:text-gray-200', 'dark:text-gray-300', 'dark:text-gray-400',
    'dark:border-gray-600', 'dark:border-gray-700', 'dark:border-gray-800',
    'dark:bg-blue-500', 'dark:bg-blue-600', 'dark:bg-blue-700',
    'dark:focus:ring-offset-gray-900',
    // Grid classes that might be generated
    {
      pattern: /^grid-cols-/
    },
    {
      pattern: /^col-span-/
    },
  ]
} 