const { createGlobPatternsForDependencies } = require('@nx/jest');

module.exports = {
  testMatch: ['<rootDir>/src/**/*.spec.ts'],
  transform: {
    '^.+\\.[tj]s$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.spec.json' }],
  },
  moduleFileExtensions: ['ts', 'js', 'html'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.spec.ts',
    '!src/main.ts',
  ],
  coverageReporters: ['html'],
  watchPathIgnorePatterns: ['node_modules'],
  transformIgnorePatterns: [
    'node_modules/(?!.*\\.mjs$)',
    ...createGlobPatternsForDependencies(__dirname),
  ],
};
