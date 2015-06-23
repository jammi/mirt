
MIRT uses a JSON-based protocol that is communicated over HTTP. Its default server uri's are `/hello` for session initialization, which is useful for getting/setting cookies for a session and for subsequent requests the `/x` uri, which shouldn't have cookies set. The history of the protocol is the [rsence](https://github.com/rsence/rsence) framework's client-server protocol, which was at version 1 and was identical apart from assumptions about the contents of messages array.


JSON protocol package format
----------------------------

`[key, {values}, [messages]]`

* `key`: session instance key, initialized and incremented as a random string by the server, digested by the client, then validated by the server. Its point is security or obfuscation per se, but to ensure client and server are sane. Each key is disposed at the next request and they require a common history to be valid.

* `values`: a set of key-value action-data pairs.

* `messages`: a list of application-specific custom messages to perform after the values are completed. proxies should just forward these as-is.


Session key validation
----------------------

The session key is a colon delimited string with the following elements:

 - Sequence number, starting with `0`
 - Protocol version, which is `2` at this point
 - Incrementing session key-sum

The client should start its first request with a session key seed, of which it saves a copy for itself until the response is handled. An initial key might look like `0:2:dOTWvWb4Jqd2MOvNi4AQ9YyWKF3kxnBfcUygM3Gp`.

Next, the server checks whether the sequence number is a `0` or not. If it is `0`, it's initializing a new session with a random key (like `dFlruqNyngzxdoueXa0s81h7zZruikde3i20iIse`). Then, it creates a SHA1 hex digest (like `20f2770df5a84bd45e61c953f62d948cb91bb1ff`) of it, using the client's key as a seed and stores that as a reference. The key in the server's response would look like: `0:2:3zBhDQXR9fRW0AQHKDDXaK6taZEBKb7LOj3dHUst`. When the response is sent, the server increments its session sequence number.

At this point, the client receives the incremental seed key set by the server, which the client validates for its next request generating the same SHA1 hex digest the server did and increments its session sequence number. Whenever the client makes its next request, it's sending the SHA1 hex digest as the key, (like `1:2:20f2770df5a84bd45e61c953f62d948cb91bb1ff`) which the server identifies, and the process increments.


Example session key exchange:
-----------------------------

An example session key exchange sequence could look like this:

**Request 1:**
    POST /hello
    ["0:2:Sf547oo4OIl5F3zPIz3rghJ74IuPSEk1dFS6TUWC",{},[]]
**Response 1:**
    200
    ["0:2:3zBhDQXR9fRW0AQHKDDXaK6taZEBKb7LOj3dHUst",{},[]]

**Request 2:**
    POST /x
    ["1:2:20f2770df5a84bd45e61c953f62d948cb91bb1ff",{},[]]
**Response 2:**
    200
    ["1:2:r5aVFiBd9MW37FlyvKQT5b4Dm1q3gHkmDwlNZRHv",{},[]]

**Request 3:**
    POST /x
    ["2:2:e6d81f847a79b550fc7ca7c0ce4cd74299333133",{},[]]
**Response 3:**
    200
    ["2:2:0dHzEWPIOZHZ4mI1xs8aw2Mg4xRPReZsq18Ob7kd",{},[]]

..and so forth. Both the `values` and  and `messages` can be empty containers, but they cannot be omitted.


Value format:
-------------

The `values` part of the package is intended for exchanging data between client and server. Each top-level key is used as the verb, and their value is an array of which the following are implemented at this point:

- `new`: Signifies the creation of a value. Each item is packed as `[key, value, type]` triplets represented as an Array, where each key is the value identifier, the value is the payload and the default number type `0` means the payload can be any valid JSON data. Future types are reserved for subsequent version of the protocol.
    - Example: `[["textfield1","initial text",0],["button34",{"label":"Click me!","enabled":true,"value":0},0]]`


- `set`: Signifies the modification of a value. Each item is packed as a key-value pair.
    - Example: `[["textfield1","modified text"],["mapapp.position":[-38.7203974,77.525263]]]`


- `del`: Signifies the removal of a value. Each item is a key.
    - Example: `["textfield1", "button34"]`

Here is an example of a combination, with the entire protocol package. Client and server are equal in version 2. In version 1, the client could only `set` values.

    [
      "59:2:z2bj2IqOIHP8YQyPVlcBnG8aNjCm2SbdcRY7cogU", {
        "new": [
          ["someapp.textfields.name", "Juha-Jarmo Heinonen", 0],
          ["anotherapp.tableData", [
            ["header0", "header1", "header2"],
            ["row1 col1", "row1 col2", "row1 col3"],
            ["row2 col1", "row2 col2", "row2 col3"]
          ], 0]
        ],
        "set": [
          ["paintapp.drawtools.rect", {
            "position": [343, 450],
            "size": [204, 78],
            "fillColor": "#ffcc00",
            "strokeColor": "#000000",
            "strokeWidth": 3
          }],
          ["someapp.checkboxes.sendSpam", false]
        ],
        "del": ["someapp.status.started", "clockapp.timer"]
      },
      [{"error": "Client doesn't support WebGL", "target": "spacegame.status"}]
    ]

A good convention is to handle `new` first, then `set` and last `del`. Future versions of MIRT will implement more verbs, which should be taken into consideration if you implement your own.


Messages format:
----------------

The messages can contain any JSON things you need in your app. The following specification are however reserved by the MIRT session handler: Objects with an `error` and a negative `code` key. These are used in responses with a negative sequence number matching the error code and a HTTP status code of 401. Avoid creating similar messages, because there will be more standard error messages in the future.

**Standard error messages**:

1. Session key mismatch error:
    `{"error": "Invalid Session Key", "code": -1}`

2. Unsupported version error:
    `{"error": "Unsupported Version", "code": -2}`

3. Invalid key format error:
    `{"error": "Invalid Key Format", "code": -3}`
