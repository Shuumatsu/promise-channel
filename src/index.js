import { make as internal_make, is_completed, take } from './channel.bs'
export * from './channel.bs'

// Receiving from a channel until it's closed is normally done using for range
// make it async iterator here
export const make = (...args) => {
    const chan = internal_make(...args)
    chan[Symbol.asyncIterator] = () => ({
        next: () => {
            if (!is_completed(chan)) {
                return take(chan).then(value => ({ value, done: false }))
            }
            return Promise.resolve({ done: true })
        }
    })
    return chan
}
