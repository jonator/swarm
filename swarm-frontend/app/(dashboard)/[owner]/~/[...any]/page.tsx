import Navbar from '@/components/navbar'
import { getUser } from '@/lib/services/users'

export default async function RepoPage({
  params,
}: { params: Promise<{ owner: string; repo: string }> }) {
  const { owner, ...rest } = await params
  const { data: user } = await getUser()

  console.log(rest)

  return (
    <>
      <Navbar user={user} tabs={[]} />

      <div className='w-full max-w-sm'>This is repo {owner}/</div>
    </>
  )
}
