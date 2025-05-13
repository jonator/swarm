import ky from "ky";

if (!process.env.NEXT_PUBLIC_API_BASE_URL) {
  throw new Error("NEXT_PUBLIC_API_BASE_URL is not defined");
}

// Create a configured instance of ky
export const apiClient = ky.create({
  prefixUrl: `${process.env.NEXT_PUBLIC_API_BASE_URL}/api`,
});
