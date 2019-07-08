const { make, put, close, is_completed } = require('../lib/index')

const sleep = async duration => new Promise(resolve => setTimeout(resolve, duration))

const player = async (name, chan) => {
    console.log(`${name} is ready!`)

    for await (const ball of chan) {
        console.log(`${name}! Hits: ${ball.hits}`)
        await sleep(100)
        !is_completed(chan) && (await put(chan, ball))
    }
}

const pingPong = async () => {
    console.log('Opening ping-pong channel!')
    const chan = make(undefined, ({ hits }) => ({ hits: hits + 1 }))

    player('ping', chan)
    player('pong', chan)

    console.log('Serving ball...')
    const ball = { hits: 0 }
    await put(chan, ball)

    await sleep(1000)
    console.log('Closing ping-pong channel...')
    close(chan)
}

pingPong()
