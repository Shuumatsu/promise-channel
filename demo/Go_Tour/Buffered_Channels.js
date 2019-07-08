const { make, put, take } = require('../../lib/index')

const main = async () => {
    const chan = make(2)

    await put(chan, 1)
    await put(chan, 2)

    console.log(await take(chan))
    console.log(await take(chan))
}

main()
