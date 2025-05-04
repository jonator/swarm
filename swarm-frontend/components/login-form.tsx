'use client'

import { submitEmailOtpAction } from '@/app/actions'
import { getEmailOtp } from '@/lib/services/users'
import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation } from '@tanstack/react-query'
import { REGEXP_ONLY_DIGITS } from 'input-otp'
import { useCallback, useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import { cn } from '../lib/utils'
import SwarmLogo from './swarm-logo'
import { Button } from './ui/button'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from './ui/form'
import { Input } from './ui/input'
import { InputOTP, InputOTPGroup, InputOTPSlot } from './ui/input-otp'

const emailSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
})

const otpSchema = z.object({
  code: z
    .string()
    .min(6, 'Code must be 6 digits')
    .max(6, 'Code must be 6 digits'),
})

export function LoginForm({
  className,
  ...props
}: React.ComponentProps<'div'>) {
  const [step, setStep] = useState<'email' | 'otp'>('email')
  const emailForm = useForm<z.infer<typeof emailSchema>>({
    resolver: zodResolver(emailSchema),
    defaultValues: {
      email: '',
    },
  })

  const otpForm = useForm<z.infer<typeof otpSchema>>({
    resolver: zodResolver(otpSchema),
    defaultValues: {
      code: '',
    },
  })

  const { mutate, isPending } = useMutation({
    mutationFn: getEmailOtp,
    onSuccess: () => {
      setStep('otp')
    },
    onError: (error) => {
      console.error(error)
      toast.error('Failed to send login code. Please try again.')
    },
  })

  const onSubmitEmail = useCallback(
    (data: z.infer<typeof emailSchema>) => {
      mutate(data.email)
    },
    [mutate],
  )

  const onSubmitOtp = useCallback(
    async (data: z.infer<typeof otpSchema>) => {
      try {
        await submitEmailOtpAction(emailForm.getValues('email'), data.code)
      } catch (error) {
        // Next.js will throw an error intentionally to try to redirect from an action
        // so we need to throw it again to let the caller handle it
        // but not treat it as an error.
        if (error instanceof Error && error.message.includes('NEXT_REDIRECT')) {
          throw error
        }
        console.error(error)
        toast.error('Failed to verify code. Please try again.')
      }
    },
    [emailForm],
  )

  const codeValue = otpForm.watch('code')

  useEffect(() => {
    if (step === 'otp' && codeValue.length === 6) {
      otpForm.handleSubmit(onSubmitOtp)()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [codeValue, step, otpForm.handleSubmit, onSubmitOtp])

  if (step === 'otp') {
    return (
      <div className={cn('flex flex-col gap-6', className)} {...props}>
        <Form {...otpForm}>
          <form
            key='otp'
            onSubmit={otpForm.handleSubmit(onSubmitOtp)}
            className='space-y-6'
          >
            <div className='flex flex-col gap-6'>
              <div className='flex flex-col items-center gap-2'>
                <a
                  href='/'
                  className='flex flex-col items-center gap-2 font-medium text-foreground'
                >
                  <div className='flex size-8 items-center justify-center rounded-md'>
                    <SwarmLogo />
                  </div>
                  <span className='sr-only'>Swarm</span>
                </a>
                <h1 className='text-xl font-bold text-foreground'>
                  Enter your code
                </h1>
                <p className='text-sm text-muted-foreground'>
                  We sent a code to {emailForm.getValues('email')}
                </p>
              </div>
              <div className='flex mx-auto flex-col gap-6'>
                <FormField
                  control={otpForm.control}
                  name='code'
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Verification Code</FormLabel>
                      <FormControl>
                        <InputOTP
                          maxLength={6}
                          pattern={REGEXP_ONLY_DIGITS}
                          {...field}
                          className='w-full'
                        >
                          <InputOTPGroup>
                            <InputOTPSlot index={0} />
                            <InputOTPSlot index={1} />
                            <InputOTPSlot index={2} />
                            <InputOTPSlot index={3} />
                            <InputOTPSlot index={4} />
                            <InputOTPSlot index={5} />
                          </InputOTPGroup>
                        </InputOTP>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>
            </div>
          </form>
        </Form>
      </div>
    )
  }

  return (
    <div className={cn('flex flex-col gap-6', className)} {...props}>
      <Form {...emailForm}>
        <form
          key='email'
          onSubmit={emailForm.handleSubmit(onSubmitEmail)}
          className='space-y-6'
        >
          <div className='flex flex-col gap-6'>
            <div className='flex flex-col items-center gap-2'>
              <a
                href='/'
                className='flex flex-col items-center gap-2 font-medium text-foreground'
              >
                <div className='flex size-8 items-center justify-center rounded-md'>
                  <SwarmLogo />
                </div>
                <span className='sr-only'>Swarm</span>
              </a>
              <h1 className='text-xl font-bold text-foreground'>
                Welcome to Swarm
              </h1>
            </div>
            <div className='flex flex-col gap-6'>
              <FormField
                control={emailForm.control}
                name='email'
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Email</FormLabel>
                    <FormControl>
                      <Input
                        placeholder='me@example.com'
                        className='bg-background text-foreground border-input'
                        {...field}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type='submit' className='w-full' disabled={isPending}>
                {isPending ? 'Sending...' : 'Send Login Code'}
              </Button>
            </div>
          </div>
        </form>
      </Form>
      <div className='text-muted-foreground text-center text-xs text-balance'>
        By clicking continue, you agree to our{' '}
        <a
          href='/'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Terms of Service
        </a>{' '}
        and{' '}
        <a
          href='/'
          className='text-primary hover:text-primary/80 underline underline-offset-4'
        >
          Privacy Policy
        </a>
        .
      </div>
    </div>
  )
}
