/**
 * CPU Load Testing Utilities
 * Functions to generate CPU load for Kubernetes autoscaling tests
 */
export interface CPULoadOptions {
  duration?: number;
  intensity?: number;
}

export interface CPULoadResult {
  message: string;
  duration: number;
  intensity: number;
  startTime: string;
}

/**
 * Generates CPU load with specified intensity and duration
 * Uses fixed parameters optimized for Kubernetes autoscaling tests
 * @returns CPU load result information
 */
export function generateCPULoad({
  duration = 10000, // 10 seconds
  intensity = 0.8, // 80% intensity
}: CPULoadOptions = {}): CPULoadResult {
  const startTime = Date.now();

  // Busy for `intensity` of every slice, idle for the rest, so the event loop
  // keeps serving requests (health probes) while the load runs
  const sliceMs = 100;
  const busyMs = sliceMs * intensity;
  const idleMs = Math.max(5, sliceMs - busyMs);

  setImmediate(() => {
    const endTime = startTime + duration;

    const loadCPU = () => {
      const sliceEnd = Math.min(Date.now() + busyMs, endTime);
      let sink = 0;

      while (Date.now() < sliceEnd) {
        for (let i = 1; i < 10000; i++) {
          sink += Math.sqrt(i) * Math.sin(i);
        }
      }

      if (Date.now() < endTime && Number.isFinite(sink)) {
        setTimeout(loadCPU, idleMs);
      }
    };

    loadCPU();
  });

  return {
    message: 'CPU load test started',
    duration,
    intensity,
    startTime: new Date(startTime).toISOString(),
  };
}
