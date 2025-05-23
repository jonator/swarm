'use client'

import { getRepositoryFrameworks } from '@/lib/services/github'
import type { Repositories, Repository } from '@/lib/services/github'
import { createRepository } from '@/lib/services/repositories'
import type { CreateRepositoryParams } from '@/lib/services/repositories'
import { cn } from '@/lib/utils/shadcn'
import { zodResolver } from '@hookform/resolvers/zod'
import { useMutation, useQuery } from '@tanstack/react-query'
import { BookIcon, Info } from 'lucide-react'
import Image from 'next/image'
import { redirect } from 'next/navigation'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import { Button } from '../ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '../ui/card'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '../ui/form'
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select'
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '../ui/tooltip'

export const ChooseRepo = ({
  repositories,
}: { repositories: Repositories }) => {
  const [repository, setRepository] = useState<Repository | null>(null)

  if (!repository) {
    return (
      <ChooseGitHubRepo
        repositories={repositories}
        onSelectRepo={(repoId) => {
          const selectedRepo = repositories.repositories.find(
            (repo) => repo.id === Number(repoId),
          )

          if (!selectedRepo) {
            console.error('Repository not found', repoId)
            return
          }

          setRepository(selectedRepo)
        }}
      />
    )
  }

  return (
    <div>
      <button
        onClick={() => setRepository(null)}
        className='flex items-center w-full justify-center gap-2 mb-4 text-lg font-medium animate-in fade-in hover:line-through transition-all'
      >
        <BookIcon className='w-5 h-5' />
        <span>{repository.full_name}</span>
      </button>
      <ChooseRepoProject
        repository={repository}
        onDone={() => {
          toast('Project created!', {
            description: 'Your project has been successfully created.',
          })
          redirect(`/${repository.owner.login}/${repository.name}`)
        }}
      />
    </div>
  )
}

const ChooseGitHubRepo = ({
  repositories: { repositories },
  onSelectRepo,
}: { repositories: Repositories; onSelectRepo: (repoId: string) => void }) => {
  // id
  const [selectedRepo, setSelectedRepo] = useState<string | null>(null)

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>Choose repository</CardTitle>
        <CardDescription>
          Select the first repository you want to use with Swarm.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <div className='py-4'>
          <Select onValueChange={setSelectedRepo}>
            <SelectTrigger className='w-full'>
              <SelectValue placeholder='Select a repository' />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                {repositories.map((repo) => (
                  <SelectItem key={repo.id} value={repo.id.toString()}>
                    {repo.full_name}
                  </SelectItem>
                ))}
              </SelectGroup>
            </SelectContent>
          </Select>
        </div>

        <Button
          variant='outline'
          type='button'
          className='w-full'
          disabled={!selectedRepo}
          onClick={() => {
            onSelectRepo(selectedRepo!)
          }}
        >
          Continue
        </Button>
      </CardContent>
    </Card>
  )
}

const projectFormSchema = z.object({
  projectType: z.string({
    required_error: 'Please select a project type.',
  }),
})
type ProjectForm = z.infer<typeof projectFormSchema>

const ChooseRepoProject = ({
  repository,
  onDone,
}: {
  repository: Repository
  onDone: () => void
}) => {
  const { data: frameworks, isLoading } = useQuery({
    queryKey: ['repo-frameworks', repository.id],
    queryFn: () =>
      getRepositoryFrameworks(
        repository.owner.login,
        repository.name,
        repository.default_branch,
      ),
  })
  const form = useForm<ProjectForm>({
    resolver: zodResolver(projectFormSchema),
  })

  const mutation = useMutation({
    mutationFn: (params: CreateRepositoryParams) => createRepository(params),
    onError: (error) => {
      console.error(error.message)
      toast.error(`Error creating repository: ${error.message}`)
    },
  })

  function onSubmit(project: ProjectForm) {
    const selectedFramework = frameworks?.find(
      (framework) => framework.type === project.projectType,
    )

    if (!selectedFramework) {
      console.error('Invalid project type')
      return
    }

    mutation.mutate({
      github_repo_id: repository.id,
      projects: [
        {
          type: selectedFramework.type,
          root_dir: selectedFramework.path,
          name: selectedFramework.name,
        },
      ],
    })

    onDone()
  }

  const selectPlaceholder = frameworks?.length
    ? `${frameworks?.length} project${frameworks?.length === 1 ? '' : 's'} type detected`
    : 'Loading...'

  return (
    <Card className='w-96'>
      <CardHeader>
        <CardTitle className='flex items-center'>Choose Project</CardTitle>
        <CardDescription>
          Projects provide a space to provide additional context to Swarm
          agents.
        </CardDescription>
      </CardHeader>
      <CardContent>
        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className='space-y-6'>
            <FormField
              control={form.control}
              name='projectType'
              render={({ field }) => (
                <FormItem>
                  <div className='flex items-center animate-in fade-in'>
                    <FormLabel>Type</FormLabel>
                    <TooltipProvider>
                      <Tooltip>
                        <TooltipTrigger>
                          <Info className='ml-2 size-4' />
                        </TooltipTrigger>
                        <TooltipContent className='max-w-xs'>
                          <p>
                            Framework or language used by the project. This
                            helps Swarm agents understand the project's
                            architecture, conventions, and dependencies.
                          </p>
                        </TooltipContent>
                      </Tooltip>
                    </TooltipProvider>
                  </div>
                  <Select
                    onValueChange={field.onChange}
                    defaultValue={field.value}
                  >
                    <FormControl>
                      <SelectTrigger
                        className={cn('w-full', isLoading && 'animate-pulse')}
                      >
                        <SelectValue placeholder={selectPlaceholder} />
                      </SelectTrigger>
                    </FormControl>
                    <SelectContent>
                      {frameworks?.map(
                        ({ type, icon, name, typeName, path }) => (
                          <SelectItem key={type} value={type}>
                            <Image
                              src={icon}
                              alt={name}
                              width={20}
                              height={20}
                            />
                            {typeName}
                            <span className='ml-2 text-secondary-foreground'>
                              {name}
                            </span>
                            {path !== name && (
                              <span className='ml-2 text-secondary-foreground/80'>
                                {path}
                              </span>
                            )}
                          </SelectItem>
                        ),
                      )}
                    </SelectContent>
                  </Select>
                  <FormMessage />
                </FormItem>
              )}
            />
            <Button
              type='submit'
              className='w-full'
              disabled={mutation.isPending}
            >
              Create
            </Button>
          </form>
        </Form>
      </CardContent>
    </Card>
  )
}
