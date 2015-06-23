'use strict'

module.exports =

  # Session timeout in seconds
  timeout: 15 * 60

  # Separate timeout for the first request to
  # prevent session flooding by inoperable
  # clients
  timeoutFirst: 15

  # Key length defines the length of the
  # random part of the key.
  keyLength: 40

