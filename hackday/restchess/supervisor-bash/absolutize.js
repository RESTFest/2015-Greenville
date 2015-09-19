/* Simple tool to absolutize a potentially relative URI */

url=require('url')
console.log(url.resolve(process.argv[2], process.argv[3]))
