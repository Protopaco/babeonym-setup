const MINIMUM_INTERVAL_MILLISECONDS = 1000;

const sleep = (milliseconds: number) => {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

const formatDuration = (milliseconds: number) => {
  const totalMinutes = Math.round(milliseconds / 60000);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;

  return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
};

/**
 * Spreads a run across a target window instead of sleeping a fixed amount
 * between batches.
 *
 * Each batch is given a time it ought to start at, and the pacer waits until
 * then. That self-corrects in both directions: a batch that ran long means the
 * next starts immediately, and a fast one absorbs the slack, so the run lands
 * near the window however variable the APIs turn out to be.
 *
 * The point is politeness rather than throughput. Wikimedia throttles automated
 * clients, and there is no reason for an overnight job to arrive as fast as it
 * possibly can.
 */
export default (totalBatches: number, spreadMinutes: number) => {
  const startedAt = Date.now();
  const requestedIntervalMilliseconds =
    totalBatches > 0 ? (spreadMinutes * 60 * 1000) / totalBatches : 0;
  const intervalMilliseconds = Math.max(
    MINIMUM_INTERVAL_MILLISECONDS,
    requestedIntervalMilliseconds,
  );

  const describe = () =>
    `${totalBatches} batch(es), one every ${(intervalMilliseconds / 1000).toFixed(1)}s, finishing in about ${formatDuration(intervalMilliseconds * totalBatches)}`;

  const waitForBatch = async (batchIndex: number) => {
    const targetStart = startedAt + batchIndex * intervalMilliseconds;
    const waitMilliseconds = targetStart - Date.now();

    if (waitMilliseconds > 0) {
      await sleep(waitMilliseconds);
    }
  };

  const estimateRemaining = (batchIndex: number) => {
    const remainingBatches = Math.max(0, totalBatches - batchIndex - 1);
    return formatDuration(remainingBatches * intervalMilliseconds);
  };

  return { describe, waitForBatch, estimateRemaining };
};
