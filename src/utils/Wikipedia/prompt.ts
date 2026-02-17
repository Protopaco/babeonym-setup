import { createInterface } from "node:readline/promises";
import { stdin as input, stdout as output } from "node:process";

const rl = createInterface({ input, output });

const ask = async (question: string): Promise<string> =>
  (await rl.question(question)).trim();

const prompt = async (question: string): Promise<string> => {
  console.log("🚀 ~ prompt ~ question:", question);
  while (true) {
    const answer = await ask(question);
    const confirmation = await ask(
      `You entered "${answer}". Is this correct? (y/n): `,
    );

    if (confirmation.toLowerCase() === "y") return answer;
  }
};

export const closePrompt = (): void => {
  rl.close();
};

export default prompt;
