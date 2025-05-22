export default async function RepoPage({
  params,
}: { params: Promise<{ owner: string; repo: string }> }) {
  const { owner, repo } = await params

  return (
    <div className='bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10'>
      <div className='w-full max-w-sm'>
        This is repo {owner}/{repo}
      </div>
    </div>
  )
}
