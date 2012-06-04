class NotFoundError extends Error
  constructor: (@msg) ->
    @name = 'NotFound'
    @status = 404
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee
    
class NotImplementedError extends Error
  constructor: (@msg) ->
    @name = 'NotImplemented'
    @status = 501
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee

class ValidationError extends Error
  constructor: (@msg) ->
    @name = 'ValidationError'
    @status = 400
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee
    
class ArgumentError extends Error
  constructor: (@msg) ->
    @name = 'ArgumentError'
    @status = 400
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee

class RequestError extends Error
  constructor: (@msg) ->
    @name = 'RequestError'
    @status = 400
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee
    
class DatabaseReadError extends Error
  constructor: (@msg) ->
    @name = 'DatabaseReadError'
    @status = 500
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee
    
class DatabaseWriteError extends Error
  constructor: (@msg) ->
    @name = 'DatabaseWriteError'
    @status = 500
    Error.call @, msg
    Error.captureStackTrace @, arguments.callee
    
module.exports =
  NotFoundError: NotFoundError
  NotImplementedError: NotImplementedError
  ValidationError: ValidationError
  DatabaseReadError: DatabaseReadError
  DatabaseWriteError: DatabaseWriteError
  RequestError: RequestError
  ArgumentError: ArgumentError