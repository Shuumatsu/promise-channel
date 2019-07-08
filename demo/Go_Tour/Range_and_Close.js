const { make, put, close } = require('../../lib/index')

const fibonacci = async (n, chan) => {
    let [x, y] = [0, 1]
    for (let i = 0; i < n; i++) {
        await put(chan, i)
        ;[x, y] = [y, x + y]
    }
    close(chan)
}

const main = async () => {
    const chan = make(10)

    fibonacci(10, chan)

    for await (const item of chan) {
        if (item === 5) {
            break
        }
        console.log(item)
    }
}

main()
