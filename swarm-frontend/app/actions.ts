"use server";

import { submitGithubAuth } from "@/lib/services/auth";
import { cookies } from "next/headers";

export async function submitGithubAuthCode(code: string) {
  const [{ token }, cookieStore] = await Promise.all([
    submitGithubAuth(code),
    cookies(),
  ]);
  cookieStore.set("access_token", token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    // Same as JWT token expiration
    maxAge: 60 * 60 * 24 * 7, // 7 days in seconds
  });
}
