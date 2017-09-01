require 'bitgo/v1/api'
require 'bitgo/v2/api'
require 'uri'
require 'net/http'
require 'json'

module Bitgo
  class ApiError < RuntimeError; end
end
