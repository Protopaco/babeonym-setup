/**
 * 504 is deliberately absent. From the Wikidata query service it means the
 * query itself exceeded the sixty-second limit, and re-sending the identical
 * query cannot fix that — it just spends five minutes proving it. Callers that
 * can make the request smaller handle it instead.
 */
const RETRYABLE_STATUS_CODES = new Set([429, 500, 502, 503]);

const sleep = (milliseconds: number) => {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

/**
 * Wikimedia throttles automated clients and asks that Retry-After be honoured.
 * Anything the run gives up on is safe to lose: completed names are already in
 * source_documents, so the stage picks up where it stopped on the next run.
 */
export default async (
  requestUrl: string,
  requestInit: RequestInit,
  maxAttempts = 5,
): Promise<Response> => {
  let attempt = 0;

  while (true) {
    attempt++;
    const response = await fetch(requestUrl, requestInit);

    if (response.ok) {
      return response;
    }

    if (!RETRYABLE_STATUS_CODES.has(response.status) || attempt >= maxAttempts) {
      throw new Error(
        `Request failed: ${response.status} ${response.statusText} (${requestUrl})`,
      );
    }

    const retryAfterHeader = response.headers.get("retry-after");
    const retryAfterSeconds = retryAfterHeader
      ? Number.parseInt(retryAfterHeader, 10)
      : Number.NaN;
    const waitMilliseconds = Number.isFinite(retryAfterSeconds)
      ? retryAfterSeconds * 1000
      : 2 ** attempt * 1000;

    console.warn(
      `  ${response.status} ${response.statusText}; waiting ${waitMilliseconds}ms before attempt ${attempt + 1} of ${maxAttempts}`,
    );

    await sleep(waitMilliseconds);
  }
};
