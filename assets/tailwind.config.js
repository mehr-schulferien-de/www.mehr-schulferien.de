module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web/**/*.*ex',
    '../lib/*_web/**/*.heex'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  // Production optimizations
  ...(process.env.NODE_ENV === 'production' ? {
    // Remove unused styles in production
    content: {
      files: [
        './js/**/*.js',
        '../lib/*_web/**/*.*ex',
        '../lib/*_web/**/*.heex'
      ],
      // Safelist commonly dynamically generated classes
      safelist: [
        // Day type colors that might be dynamically generated
        /^bg-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/,
        /^text-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/,
        /^border-(red|green|blue|yellow|orange|purple|pink|gray)-(100|200|300|400|500|600|700|800|900)$/,
        // Grid classes that might be generated
        /^grid-cols-/,
        /^col-span-/,
        // Responsive classes
        /^(sm|md|lg|xl|2xl):/
      ]
    }
  } : {})
} 