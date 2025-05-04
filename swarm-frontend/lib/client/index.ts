import ky from 'ky'

// Create a configured instance of ky
export const apiClient = ky.create({
  prefixUrl: `${process.env.NEXT_PUBLIC_API_BASE_URL}/api`,
})
