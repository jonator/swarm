import { apiClient } from '../client'
interface GetEmailOtpResponse {
  message: string
}

export const getEmailOtp = async (email: string) =>
  apiClient
    .get('users/email_otp', { searchParams: { email } })
    .json<GetEmailOtpResponse>()

interface SubmitEmailOtpResponse {
  token: string
}

export const submitEmailOtp = async (email: string, code: string) =>
  apiClient
    .post('users/email_otp', { searchParams: { email, code } })
    .json<SubmitEmailOtpResponse>()
