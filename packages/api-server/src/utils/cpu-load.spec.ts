import { generateCPULoad } from './cpu-load';

describe('generateCPULoad', () => {
  // real clock: the busy loop measures elapsed time with Date.now()
  beforeEach(() => jest.useFakeTimers({ doNotFake: ['Date', 'performance'] }));
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

  it('keeps working until the duration elapses', () => {
    const setTimeoutSpy = jest.spyOn(global, 'setTimeout');

    generateCPULoad({ duration: 1000, intensity: 0.5 });
    jest.advanceTimersByTime(2000);

    // regression: work used to stop after the first slice when the sum was negative
    expect(setTimeoutSpy.mock.calls.length).toBeGreaterThan(1);
  });

  it('respects custom options', () => {
    expect(generateCPULoad({ duration: 50, intensity: 0.1 })).toMatchObject({
      duration: 50,
      intensity: 0.1,
    });
  });
});
