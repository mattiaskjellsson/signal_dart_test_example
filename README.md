# What's this?

Try to make out how this signal protocol library is working as needed in another project.

## Dependencies

This is trying to work out how [https://pub.dev/packages/libsignal_protocol_dart] is working with another project.

## Installation/Before running

* Fork the code for the library [https://github.com/MixinNetwork/libsignal_protocol_dart] into this projects /packages folder (or link it or something).

* You need some server to place keys so that they can be exchanged. If nothing else, [https://github.com/mattiaskjellsson/flutter_xmpp_chat_back] can be used.

* You need a socketIo server for message exchange. If nothing else, the following can be used.

``` javascript
const server = require('http').createServer()
const io = require('socket.io')(server)

io.on('connect', function (client) {

  console.log('client connect...', client.id);

  client.on('typing', (data) => {
    console.log('typing', data);
    io.emit('typing', data)
  })

  client.on('message', (data) => {
    console.log(data);
    io.emit('message', data)
  })

  client.on('disconnect', (data) => {
    console.log('client disconnect...', data, client.id)
  })

  client.on('error', (err) => {
    console.log('received error from client:', client.id)
    console.log(err)
  })
})

var server_port = process.env.PORT || 3002;

server.listen(server_port, (err) => {
  if (err) throw err
  console.log('Listening on port %d', server_port);
});
```

Important is to use this socketIO version.
```
    "socket.io": "^4.1.3"
```

## Running

* Start key exchange server
* Start socketIO server
* Make sure that the hosts are set correctly (see main.dart).

``` bash
$dart /lib/main.dart
```

```
      .--..--..--..--..--..--.
    .' \  (`._   (_)     _   \
  .'    |  '._)         (_)  |
  \ _.')\      .----..---.   /
  |(_.'  |    /    .-\-.  \  |
  \     0|    |   ( O| O) | o|
   |  _  |  .--.____.'._.-.  |
   \ (_) | o         -` .-`  |
    |    \   |`-._ _ _ _ _\ /
    \    |   |  `. |_||_|   |
    | o  |    \_      \     |     -.   .-.
    |.-.  \     `--..-'   O |     `.`-' .'
  _.'  .' |     `-.-'      /-.__   ' .-'
.' `-.` '.|='=.='=.='=.='=|._/_ `-'.'
`-._  `.  |________/\_____|    `-.'
   .'   ).| '=' '='\/ '=' |
   `._.`  '---------------'
           //___\   //___\
             ||       ||
    LGB      ||_.-.   ||_.-.
            (_.--__) (_.--__)
```