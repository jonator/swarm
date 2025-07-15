interface HeaderProps {
  title: string
  description: string
}

export function Header({ title, description }: HeaderProps) {
  return (
    <header className='flex items-center justify-between pt-6'>
      <h1 className='text-2xl font-bold'>{title}</h1>
      <p className='text-muted-foreground'>{description}</p>
    </header>
  )
}
