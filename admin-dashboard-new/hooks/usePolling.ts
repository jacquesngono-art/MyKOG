import { useEffect, useRef } from 'react';

export function usePolling(callback: () => void, intervalMs: number = 30000) {
  const savedCallback = useRef(callback);

  useEffect(() => {
    savedCallback.current = callback;
  }, [callback]);

  useEffect(() => {
    const tick = async () => {
      try {
        await savedCallback.current();
      } catch {
        // silencieux – erreurs de polling attendues si le serveur est temporairement indisponible
      }
    };
    tick();
    const id = setInterval(tick, intervalMs);
    return () => clearInterval(id);
  }, [intervalMs]);
}
