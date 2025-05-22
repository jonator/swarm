export default async function OwnerPage({
  params,
}: { params: Promise<{ owner: string }> }) {
  const { owner } = await params

  return (
    <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
      <div className='w-full max-w-sm'>This is {owner} page</div>
    </div>
  )
}
