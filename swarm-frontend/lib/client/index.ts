import ky from 'ky'

if (!process.env.NEXT_PUBLIC_API_BASE_URL) {
  throw new Error('NEXT_PUBLIC_API_BASE_URL is not defined')
}

type ApiError = {
  message: string
}

// Create a configured instance of ky
export const apiClient = ky.create({
  prefixUrl: `${process.env.NEXT_PUBLIC_API_BASE_URL}/api`,
  hooks: {
    beforeError: [
      async (error) => {
        // We want to make sure error bodies are always included in the error message
        // This is helpful when our zero code instrumentation setup captures the error

        // If we don't do this, the default ky.HTTPError message is:
        // `Request failed with ${reason}: ${request.method} ${request.url}`
        // See: https://github.com/sindresorhus/ky/blob/main/source/errors/HTTPError.ts
        const { response } = error
        if (response?.body) {
          // biome-ignore lint/suspicious/noExplicitAny: <explanation>
          let body: any
          try {
            body = (await response.json()) as ApiError
            error.message = body.message
          } catch {}
        }

        return error
      },
    ],
  },
})
