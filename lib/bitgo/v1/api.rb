module Bitgo
	module V1

		class Api

			attr_accessor :session_token

			TEST = 'https://test.bitgo.com/api/v1'
			LIVE = 'https://www.bitgo.com/api/v1'
			EXPRESS = 'http://127.0.0.1:3080/api/v1'

			def initialize(end_point)
				@end_point = end_point
			end

			###############
			# User APIs
			###############

			def session_info
				call :get, '/user/session'
			end

			# Get a token for first-party access to the BitGo API. First-party access is only intended for users accessing their own BitGo accounts.
			# For 3rd party access to the BitGo API on behalf of another user, please see Partner Authentication.
			def login(email: email, password: password, otp: otp)
				login_params = {
					email: email,
					password: password,
					otp: otp
				}

				with_auth_token = false
				parse_response_as_json = true

				call :post, '/user/login', login_params, parse_response_as_json, with_auth_token
			end

			# Get a token for first-party access to the BitGo API. First-party access is only intended for users accessing their own BitGo accounts.
			# For 3rd party access to the BitGo API on behalf of another user, please see Partner Authentication.
			def logout
				call :get, '/user/logout'
			end

			def send_otp(force_sms: false)
				call :post, '/user/sendotp', forceSMS: force_sms
			end

			def session_information
				call :get, '/user/session'
			end

			def unlock(otp: otp, duration_seconds: duration_seconds)
				unlock_params = {
					otp: otp,
					duration: duration_seconds
				}
				call :post, '/user/unlock', unlock_params
			end

			def lock
				call :post, '/user/lock'
			end

			###############
			# Keychains API
			###############

			def list_keychains
				call :get, '/keychain'
			end

			# Bitgo express function
			# Client-side function to create a new keychain.
			# Optionally, a single parameter, 'seed’, may be provided which uses a deterministic seed to create your keychain. The seed should be an array of numbers at least 32 elements long. Calling this function with the same seed will generate the same BIP32 keychain.
			def create_keychain(seed: nil)

				if seed.present?
					seed.scan(/../).map(&:hex)
					[seed].pack('H*').unpack('C*')
					seed_arr = [seed].pack('H*').bytes.to_a
					call :post, '/keychain/local', { seed: seed_arr }
				else
					call :post, '/keychain/local'
				end
			end

			def add_keychain(xpub: xpub, encrypted_xprv: encrypted_xprv)
				call :post, '/keychain', { xpub: xpub, encrypted_xprv: encrypted_xprv }
			end

			def create_bitgo_keychain
				call :post, '/keychain/bitgo'
			end

			###############
			# Address Labels API
			###############

			def list_labels
				call :get, '/labels'
			end

			def list_labels_for_wallet(wallet_id: wallet_id)
				call :get, '/labels/' + wallet_id
			end

			def set_label(wallet_id: wallet_id, address: address, label: label)
				call :put, '/labels/' + wallet_id + '/' + address, { label: label }
			end

			def delete_label(wallet_id: wallet_id, address: address)
				call :delete, '/labels/' + wallet_id + '/' + address
			end

			###############
			# Wallets API
			###############

			def list_wallets
				call :get, '/wallet'
			end

			# wallet_simple_create
			#
			# Note: Bitcoin Express API, will only work on Bitcoin Express Endpoint
			# This method is available on the client SDK as an easy way to create a wallet. It performs the following:
			#
			# 1. Creates the user keychain and the backup keychain locally on the client
			# 2. Encrypts the user keychain and backup keychain with the provided passphrase
			# 3. Uploads the encrypted user and backup keychains to BitGo
			# 4. Creates the BitGo key on the service
			# 5. Creates the wallet on BitGo with the 3 public keys above
			#
			# Example:
			# api = Bitgo::Api.new
			# api.simple_create(passphrase: '12345', label: 'label')
			#
			# {
			#             "wallet" => {
			#                          "id" => "2N2ovVLDjYpUr3RSR4Z5UiXFzBkQ1hRyNSR",
			#                       "label" => "test wallet 1",
			#                    "isActive" => true,
			#                        "type" => "safehd",
			#                      "freeze" => {},
			#                  "adminCount" => 1,
			#                     "private" => {
			#             "keychains" => [
			#                 [0] {
			#                     "xpub" => "xpub661MyMwAqRbcF5jq3P7NkbMfFK9HDEYppZXxzmAsid5AvAPF1UyN1vsuePn9HNy3ZgYgUaANt1tkpxtZ2NLxUp1qeiPApMNu2uCJivmEDob", # user key chain
			#                     "path" => "/0/0"
			#                 },
			#                 [1] {
			#                     "xpub" => "xpub661MyMwAqRbcGPnMoA7wCWnY1K2NGHUEMzaJQsjpv83mVTsodjKJDUjZEwEegztrf1uSokHDKpBMFLR79YSnH7zvgGN18EHVNMbKFVbk8rv", # user backupkey
			#                     "path" => "/0/0"
			#                 },
			#                 [2] {
			#                     "xpub" => "xpub661MyMwAqRbcEruwFJWcXjHkgTPW5cg5ZBMg9dRQyjrL49szFdrCuGvGDGpcXHWEdsj2NY4o6QxsvzfvorsZ5VH9ha3pGD8SJgATbEo7jbp", # bitgo keychain
			#                     "path" => "/0/0"
			#                 }
			#             ]
			#         },
			#                 "permissions" => "admin,spend,view",
			#                       "admin" => {
			#             "users" => [
			#                 [0] {
			#                            "user" => "552489e5c8e05d177800a5b1bf066af4",
			#                     "permissions" => "admin,spend,view"
			#                 }
			#             ]
			#         },
			#             "spendingAccount" => true,
			#            "confirmedBalance" => 0,
			#                     "balance" => 0,
			#            "unconfirmedSends" => 0,
			#         "unconfirmedReceives" => 0,
			#            "pendingApprovals" => []
			#     },
			#       "userKeychain" => {
			#                  "xpub" => "xpub661MyMwAqRbcF5jq3P7NkbMfFK9HDEYppZXxzmAsid5AvAPF1UyN1vsuePn9HNy3ZgYgUaANt1tkpxtZ2NLxUp1qeiPApMNu2uCJivmEDob",
			#                  "xprv" => "xprv9s21ZrQH143K2bfMwMaNPTQvhHJnompyTLcNCNmGAHYC3N46Twf7U8ZRo7isyYM7c5KriFYPdMnpB3CL9sKWyJYjQNri6mVNEvFXFZGx8J8",
			#         "encryptedXprv" => "{\"iv\":\"EnVDttt82SOMdk5+nxl6Yg==\",\"v\":1,\"iter\":10000,\"ks\":256,\"ts\":64,\"mode\":\"ccm\",\"adata\":\"\",\"cipher\":\"aes\",\"salt\":\"6E6KxZSKJ1U=\",\"ct\":\"PPIBVErcWkBUTl5ceqUulvDLsbZl17fhLt1CFnsA6Ay9R9NU6utNxst9SvcaeMEwItdSTUOfWvg7rokpR+0g8yHsqouf3qCiqk9RZLy0jKReje5/SC2J5SPp6yIsfT8q0y8QwKjVNx2FULLpJeHQ9yv/+TE+lvo=\"}"
			#     },
			#     "backupKeychain" => {
			#         "xpub" => "xpub661MyMwAqRbcGPnMoA7wCWnY1K2NGHUEMzaJQsjpv83mVTsodjKJDUjZEwEegztrf1uSokHDKpBMFLR79YSnH7zvgGN18EHVNMbKFVbk8rv",
			#         "xprv" => "xprv9s21ZrQH143K3uhth8avqNqoTHBsrpkNzmehcVLDMnWncfYf6C13fgR5PfKkFukcGF2vjopkDXEaYxKoxb6c9WXtbJga7aR3C8cgCr1v8vh"
			#     },
			#      "bitgoKeychain" => {
			#            "xpub" => "xpub661MyMwAqRbcEruwFJWcXjHkgTPW5cg5ZBMg9dRQyjrL49szFdrCuGvGDGpcXHWEdsj2NY4o6QxsvzfvorsZ5VH9ha3pGD8SJgATbEo7jbp",
			#         "isBitGo" => true,
			#            "path" => "m"
			#     },
			#            "warning" => "Be sure to backup the backup keychain -- it is not stored anywhere else!"
			# }
			def simple_create_wallet(passphrase: passphrase, label: label)
				call :post, '/wallets/simplecreate', {passphrase: passphrase, label: label}
			end

			# This API creates a new wallet for the user. The keychains to use with the new wallet must be registered with BitGo prior to using this API.
			# BitGo currently only supports 2-of-3 (e.g. m=2 and n=3) wallets. The third keychain, and only the third keychain, must be a BitGo key.
			# The first keychain is by convention the user key, with it’s encrypted xpriv is stored on BitGo.
			# BitGo wallets currently are hard-coded with their root at m/0/0 across all 3 keychains (however, older legacy wallets may use different key paths). Below the root, the wallet supports two chains of addresses, 0 and 1. The 0-chain is for external receiving addresses, while the 1-chain is for internal (change) addresses.
			# The first receiving address of a wallet is at the BIP32 path m/0/0/0/0, which is also the ID used to refer to a wallet in BitGo’s system. The first change address of a wallet is at m/0/0/1/0.
			#
			# label: string	(Required)	A label for this wallet
			# m: number	(Required)	The number of signatures required to redeem (must be 2)
			# n: number	(Required)	The number of keys in the wallet (must be 3)
			# keychains: array	(Required)	An array of n keychain xpubs to use with this wallet; last must be a BitGo key
			# enterprise :string (Optional)	Enterprise ID to create this wallet under.
			def add_wallet(label: label, m: m, n: n, keychains: keychains, enterprise: nil)
				wallet_params = { label: label, m: m, n: n, keychains: keychains }
				if enterprise.present?
					wallet_params[:enterprise] = enterprise
				end

				call :post, '/wallet', wallet_params
			end

			# Lookup wallet information, returning the wallet model including balances, permissions etc. The ID of a wallet is its first receiving address (/0/0)
			#
			# Response:
			# id				id of the wallet (also the first receiving address)
			# label				the wallet label, as shown in the UI
			# index				the index of the address within the chain (0, 1, 2, …)
			# private			contains summarised version of keychains
			# permissions		user’s permissions on this wallet
			# admin				policy information on the wallet’s administrators
			# pendingApprovals	pending transaction approvals on the wallet
			# confirmedBalance	the confirmed balance
			# balance	the balance, including transactions with 0 confirmations
			def get_wallet(wallet_id: wallet_id)
				call :get, '/wallet/' + wallet_id
			end

			# Gets a list of addresses which have been instantiated for a wallet using the New Address API.
			def list_wallet_addresses(wallet_id: wallet_id)
				call :get, '/wallet/' + wallet_id + '/addresses'
			end

			# Creates a new address for an existing wallet. BitGo wallets consist of two independent chains of addresses, designated 0 and 1.
			# The 0-chain is typically used for receiving funds, while the 1-chain is used internally for creating change when spending from a wallet.
			# It is considered best practice to generate a new receiving address for each new incoming transaction, in order to help maximize privacy.
			def create_address(wallet_id: wallet_id, chain: chain)
				call :post, '/wallet/' + wallet_id + '/address/' + chain
			end

			def send_coins_to_address(wallet_id: wallet_id, address: address, amount: amount, wallet_passphrase: wallet_passphrase, min_confirmations: min_confirmations, fee: fee)
				call :post, '/sendcoins', {
					wallet_id: wallet_id,
					address: address,
					amount: amount,
					wallet_passphrase: wallet_passphrase,
					min_confirmations: min_confirmations,
					fee: fee
				}
			end

			def send_coins_to_multiple_addresses()

			end

			###############
			# Webhook APIs
			###############
			# Adds a Webhook that will result in a HTTP callback at the specified URL from BitGo when events are triggered. There is a limit of 5 Webhooks of each type per wallet.
			#
			# type				string	(Required)	type of Webhook, e.g. transaction
			# url				string	(Required)	valid http/https url for callback requests
			# numConfirmations	integer	(Optional)	number of confirmations before triggering the webhook. If 0 or unspecified, requests will be sent to the callback endpoint will be called when the transaction is first seen and when it is confirmed.
			def add_webhook(wallet_id: wallet_id, type: type, url: url, confirmations: confirmations)
				add_webhook_params = {
					type: type,
					url: url,
					numConfirmations: confirmations
				}
				call :post, '/wallet/' + wallet_id + '/webhooks', add_webhook_params
			end


			def remove_webhook(wallet_id: wallet_id, type: type, url: url)
				remove_webhook_params = {
					type: type,
					url: url
				}
				call :delete, '/wallet/' + wallet_id + '/webhooks', remove_webhook_params
			end

			def list_webhooks(wallet_id: wallet_id)
				call :get, '/wallet/' + wallet_id + '/webhooks'
			end

			###############
			# Utilities (Via Bitgo Express API)
			###############

			def encrypt(input: input, password: password)
				call :post, '/encrypt', { input: input, password: password }
			end

			def decrypt(input: input, password: password)
				call :post, '/decrypt', { input: input, password: password }
			end

			# Client-side function to verify that a given string is a valid Bitcoin Address. Supports both v1 addresses (e.g. “1…”) and P2SH addresses (e.g. “3…”).
			def verify_address(address: address)
				verify_address_params = {
					address: address
				}
				call :post, '/verifyaddress', verify_address_params
			end


		protected

			###############
			# HTTP call
			###############

			# Perform HTTP call
			# path parameter must being with a /
			def call(method, path, params = {}, parse_response_as_json = true, with_auth_token = true)

				# path must begin with slash
				uri = URI(@end_point + path)

				# Build the connection
				http = Net::HTTP.new(uri.host, uri.port)

				if uri.scheme == 'https'
					http.use_ssl = true
				end

				request = nil
				if method == :get
					request = Net::HTTP::Get.new(uri.request_uri)

				elsif method == :post
					request = Net::HTTP::Post.new(uri.request_uri)
				elsif method == :delete
					request = Net::HTTP::Delete.new(uri.request_uri)
				elsif method == :put
					request = Net::HTTP::Put.new(uri.request_uri)
				else
					raise 'Unsupported request method'
				end

				request.body = params.to_json

				# Set JSON body
				request.add_field('Content-Type', 'application/json')

				# Add authentication header
				if with_auth_token == true && @session_token.nil? == false
					request.add_field('Authorization', 'Bearer ' + @session_token)
				end

				response = http.request(request)

				if parse_response_as_json == true
					json_resp = nil
					begin
						json_resp = JSON.parse(response.body)
					rescue => e
						raise ApiError.new("Error Parsing Bitgo's response as JSON: #{e} , Bitgo response: #{response.body}")
					end

					if json_resp.kind_of?(Hash) && json_resp["error"].nil? == false
						raise ApiError.new(json_resp["error"])
					end

					return json_resp
				else
					return response.body
				end
			end

		end

	end
end
