export default async (queryParams: any) => {
  console.log("Wikipedia client initialized");

  const apiUrl =
    process.env.WIKI_API_URL || "https://en.wikipedia.org/w/api.php";
  const params = new URLSearchParams(queryParams);

  try {
    const response = await fetch(`${apiUrl}?${params.toString()}`);
    if (!response.ok) {
      throw new Error(
        `Wikipedia API error: ${response.status} ${response.statusText}`,
      );
    }
    const data = await response.json();
    return data;
  } catch (error) {
    console.error("Error fetching from Wikipedia API:", error);
    throw error;
  }
};
