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

  // Start CPU intensive work in background
  setImmediate(() => {
    const endTime = startTime + duration;

    const loadCPU = () => {
      // Perform CPU intensive calculations
      let calculationResult = 0;
      const iterations = 1500000 * intensity; // Adjusted for consistent load

      for (let i = 0; i < iterations; i++) {
        calculationResult +=
          Math.sqrt(i) * Math.sin(i) * Math.cos(i) * Math.tan(i / 1000);
      }

      // Use result to prevent optimization
      if (calculationResult > 0) {
        const targetIterationTime = 150; // Target 150ms per iteration
        const sleepTime = Math.max(5, targetIterationTime * (1 - intensity));

        if (Date.now() < endTime) {
          setTimeout(loadCPU, sleepTime);
        }
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
