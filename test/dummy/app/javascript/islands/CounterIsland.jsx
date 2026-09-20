import { useState } from 'react'

// Toy island for the react-island infrastructure previews and Cypress specs.
// A counter proves the full loop (props from Stimulus values, client-side
// state, events); the "explode" button throws during render on purpose so the
// ErrorBoundary in ReactIslandController can be exercised from the browser.
export default function CounterIsland ({ label, start, explodeLabel }) {
  const [count, setCount] = useState(start)
  const [broken, setBroken] = useState(false)

  if (broken) throw new Error('CounterIsland: render explosion requested')

  return (
    <div className='card bg-base-100 border border-base-300 p-4 gap-2 w-64' data-testid='counter-island'>
      <p className='font-bold'>{label}</p>
      <p className='text-2xl tabular-nums' data-testid='count'>{count}</p>
      <div className='flex gap-2'>
        <button
          type='button'
          className='btn btn-primary btn-sm'
          data-testid='increment'
          onClick={() => setCount(count + 1)}
        >
          +1
        </button>
        <button
          type='button'
          className='btn btn-error btn-outline btn-sm'
          data-testid='explode'
          onClick={() => setBroken(true)}
        >
          {explodeLabel}
        </button>
      </div>
    </div>
  )
}
