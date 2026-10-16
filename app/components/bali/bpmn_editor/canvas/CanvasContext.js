import { createContext, useContext } from 'react'

// What the node and edge components need beyond their own React Flow props:
// the translator, the computed routes, the pool origin and the editor's
// callbacks. One context instead of copying all of it into every node's data
// keeps node objects stable across renders that only change the callbacks.
export const CanvasContext = createContext(null)
export const useCanvas = () => useContext(CanvasContext)
