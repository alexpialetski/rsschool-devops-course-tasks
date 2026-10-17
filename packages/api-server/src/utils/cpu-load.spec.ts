import { generateCPULoad } from './cpu-load';

describe('generateCPULoad', () => {
  beforeEach(() => jest.useFakeTimers());
  afterEach(() => jest.useRealTimers());

  it('returns defaults without blocking the caller', () => {
    const result = generateCPULoad();

    expect(result).toMatchObject({
      message: 'CPU load test started',
      duration: 10000,
      intensity: 0.8,
    });
    expect(new Date(result.startTime).toString()).not.toBe('Invalid Date');
  });

  it('respects custom options', () => {
    expect(generateCPULoad({ duration: 50, intensity: 0.1 })).toMatchObject({
      duration: 50,
      intensity: 0.1,
    });
  });
});
