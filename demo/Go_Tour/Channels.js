// https://tour.golang.org/concurrency/2
const { make, put, take } = require('../../lib/index')

const sum = async (arr, chan) => {
    let sum = 0
    for (const v of arr) {
        sum += v
    }
    await put(chan, sum)
}

const main = async () => {
    const arr1 = [7, 2, 8]
    const arr2 = [-9, 4, 0]
    const chan = make()

    sum(arr1, chan)
    sum(arr2, chan)

    const [x, y] = [await take(chan), await take(chan)]

    console.log(x, y, x + y)
}

main()
