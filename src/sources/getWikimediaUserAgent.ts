import dotenv from "dotenv";

dotenv.config();

/**
 * Wikimedia asks automated clients to identify themselves with a descriptive
 * User-Agent that includes a way to make contact. The contact string is read
 * from the environment so it stays out of the repository.
 */
export default () => {
  const wikimediaContact = process.env.WIKIMEDIA_CONTACT;

  if (!wikimediaContact) {
    throw new Error(
      "WIKIMEDIA_CONTACT is not set. Wikimedia asks for a contact address in the User-Agent of automated requests. Add it to .env — see .env.example.",
    );
  }

  return `Babeonym-data-builder/1.0 (${wikimediaContact})`;
};
