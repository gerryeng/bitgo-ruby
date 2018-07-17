module Bitgo
  module V1

    class Api

      attr_accessor :session_token, :default_wallet_id, :default_wallet_passphrase

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
      def login(email:, password:, otp:)
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

      def unlock(otp:, duration_seconds:)
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

      # Query Parameters
      # Parameter 	Type    	Required 	Description
      # skip       	number 	  No      	The starting index number to list from. Default is 0.
      # limit 	    number   	No 	      Max number of results to return in a single call (default=100, max=500)
      def list_keychains(params: {})
        call :get, '/keychain', params
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

      def add_keychain(xpub:, encrypted_xprv:)
        call :post, '/keychain', { xpub: xpub, encrypted_xprv: encrypted_xprv }
      end

      def create_bitgo_keychain
        call :post, '/keychain/bitgo'
      end

      def get_keychain(xpub:)
        call :post, "/keychain/#{xpub}"
      end

      ###############
      # Address Labels API
      ###############

      def list_labels
        call :get, '/labels'
      end

      def list_labels_for_wallet(wallet_id: default_wallet_id)
        call :get, '/labels/' + wallet_id
      end

      def set_label(wallet_id: default_wallet_id, address:, label:)
        call :put, '/labels/' + wallet_id + '/' + address, { label: label }
      end

      def delete_label(wallet_id: default_wallet_id, address:)
        call :delete, '/labels/' + wallet_id + '/' + address
      end

      ###############
      # Wallets API
      ###############

      # QUERY Parameters
      # Parameter 	  Type  	Required 	Description
      # enterpriseId 	string 	No      	Filter list by Enterprise ID
      # getbalances 	boolean	No 	      Set to true to return the “balance” field for each wallet.
      # limit 	      number 	No 	      Max number of results to return in a single call (default=25, max=250)
      # skip 	        number 	No 	      The starting index number to list from. Default is 0.
      def list_wallets(params: {})
        call :get, '/wallet', params
      end

      # QUERY Parameters
      # Parameter   	Type   	Required 	Description
      # skip      	  number 	No 	      The starting index number to list from. Default is 0.
      # limit 	      number 	No 	      Max number of results to return in a single call (default=25, max=250)
      # compact 	    boolean No 	      Omit inputs and outputs in the transaction results
      # minHeight 	  number 	No 	      A lower limit of blockchain height at which the transaction was confirmed. Does not filter unconfirmed transactions.
      # maxHeight 	  number 	No 	      An upper limit of blockchain height at which the transaction was confirmed. Filters unconfirmed transactions if set.
      # minConfirms  number 	No 	      Only shows transactions with at least this many confirmations, filters transactions that have fewer confirmations.
      def list_wallet_transactions(wallet_id: default_wallet_id, params: {})
        call :get, "/wallet/#{wallet_id}/tx", params
      end

      def get_wallet_transaction(wallet_id: default_wallet_id, tx_id:)
        call :get, "/wallet/#{wallet_id}/tx/#{tx_id}"
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
      def simple_create_wallet(passphrase:, label:)
        call :post, '/wallets/simplecreate', {passphrase: passphrase, label: label}
      end

      # This API creates a new wallet for the user. The keychains to use with the new wallet must be registered with BitGo prior to using this API.
      # BitGo currently only supports 2-of-3 (e.g. m=2 and n=3) wallets. The third keychain, and only the third keychain, must be a BitGo key.
      # The first keychain is by convention the user key, with it’s encrypted xpriv is stored on BitGo.
      # BitGo wallets currently are hard-coded with their root at m/0/0 across all 3 keychains (however, older legacy wallets may use different key paths). Below the root, the wallet supports two chains of addresses, 0 and 1. The 0-chain is for external receiving addresses, while the 1-chain is for internal (change) addresses.
      # The first receiving address of a wallet is at the BIP32 path m/0/0/0/0, which is also the ID used to refer to a wallet in BitGo’s system. The first change address of a wallet is at m/0/0/1/0.
      #
      # label: string (Required)  A label for this wallet
      # m: number (Required)  The number of signatures required to redeem (must be 2)
      # n: number (Required)  The number of keys in the wallet (must be 3)
      # keychains: array  (Required)  An array of n keychain xpubs to use with this wallet; last must be a BitGo key
      # enterprise :string (Optional) Enterprise ID to create this wallet under.
      def add_wallet(label:, m:, n:, keychains:, enterprise: nil)
        wallet_params = { label: label, m: m, n: n, keychains: keychains }
        if enterprise.present?
          wallet_params[:enterprise] = enterprise
        end

        call :post, '/wallet', wallet_params
      end

      # Lookup wallet information, returning the wallet model including balances, permissions etc. The ID of a wallet is its first receiving address (/0/0)
      #
      # Response:
      # id        id of the wallet (also the first receiving address)
      # label       the wallet label, as shown in the UI
      # index       the index of the address within the chain (0, 1, 2, …)
      # private     contains summarised version of keychains
      # permissions   user’s permissions on this wallet
      # admin       policy information on the wallet’s administrators
      # pendingApprovals  pending transaction approvals on the wallet
      # confirmedBalance  the confirmed balance
      # balance the balance, including transactions with 0 confirmations
      def get_wallet(wallet_id: default_wallet_id)
        call :get, '/wallet/' + wallet_id
      end

      # Gets a list of addresses which have been instantiated for a wallet using the New Address API.
      def list_wallet_addresses(wallet_id: default_wallet_id)
        call :get, '/wallet/' + wallet_id + '/addresses'
      end

      # Creates a new address for an existing wallet. BitGo wallets consist of two independent chains of addresses, designated 0 and 1.
      # The 0-chain is typically used for receiving funds, while the 1-chain is used internally for creating change when spending from a wallet.
      # It is considered best practice to generate a new receiving address for each new incoming transaction, in order to help maximize privacy.
      def create_address(wallet_id: default_wallet_id, chain: 0)
        call :post, '/wallet/' + wallet_id + '/address/' + chain
      end

      def send_coins_to_address(wallet_id: default_wallet_id, address:, amount:, wallet_passphrase: default_wallet_passphrase, min_confirmations: nil, fee: nil)
        call :post, '/sendcoins', {
          wallet_id: wallet_id,
          address: address,
          amount: amount,
          wallet_passphrase: wallet_passphrase,
          min_confirmations: min_confirmations,
          fee: fee
        }
      end

      # Send Transaction to Many (BitGo Express)
      #
      # Parameter                     Type     Required  Description
      # recipients                    Array    Yes       Objects describing the receive address and amount.
      # walletPassphrase              String   Yes       Passphrase to decrypt the wallet’s private key.
      # minValue                      Integer  No        Ignore unspents smaller than this amount of satoshis
      # maxValue                      Integer  No        Ignore unspents larger than this amount of satoshis
      # sequenceId                    String   No        A custom user-provided string that can be used to uniquely identify the state of this transaction before and after signing
      # feeRate                       Integer  No        The desired fee rate for the transaction in satoshis/kb
      # minConfirms                   Integer  No        The required number of confirmations for each transaction input
      # enforceMinConfirmsForChange   Boolean  No        Whether to enforce the required number of confirmations for change outputs
      # targetWalletUnspents          Integer  No
      #
      # @recipients Array
      # Each recipient object has the following key-value-pairs:
      # Key        Type    Value
      # address    String  Destination address
      # amount     Integer Satoshis to send in transaction
      #            String  String representation of satoshis to send in transaction
      # gasPrice   Integer No
      #
      # Response
      #
      # Returns the newly created transaction description object.
      #
      # Field    Description
      # txid     Blockchain transaction ID
      # status   Status of transaction

      def send_many(wallet_id: default_wallet_id,
        wallet_passphrase: default_wallet_passphrase,
        recipients:,
        min_value: nil,
        max_value: nil,
        sequence_id: nil,
        fee_rate: nil,
        max_fee_rate: nil,
        min_confirms: nil,
        enforce_min_confirms_for_change: nil,
        target_wallet_unspents: nil,
        fee_tx_confirm_target: nil,
        message: nil,
        coin: nil
      )

        params = {
          walletPassphrase: wallet_passphrase,
          recipients: recipients
        }

        params[:minValue] = min_value unless min_value.nil?
        params[:maxValue] = max_value unless max_value.nil?
        params[:sequenceId] = sequence_id unless sequence_id.nil?
        params[:feeRate] = fee_rate unless fee_rate.nil?
        params[:maxFeeRate] = max_fee_rate unless max_fee_rate.nil?
        params[:minConfirms] = min_confirms unless min_confirms.nil?
        params[:enforceMinConfirmsForChange] = enforce_min_confirms_for_change unless enforce_min_confirms_for_change.nil?
        params[:targetWalletUnspents] = target_wallet_unspents unless target_wallet_unspents.nil?
        params[:feeTxConfirmTarget] = fee_tx_confirm_target unless fee_tx_confirm_target.nil?
        params[:message] = message unless message.nil?

        call :post, "/wallet/#{wallet_id}/sendmany", params
      end

      ###############
      # Wallets API Advanced
      ###############

      # List Wallet Unspents
      #                    Required?
      # target       number    No   The API will attempt to return enough unspents to accumulate to at least this amount (in satoshis).
      # skip         number    No   The starting index number to list from. Default is 0.
      # limit        number    No   Max number of results to return in a single call (default=100, max=250)
      # minConfirms  number    No   Only include unspents with at least this many confirmations.
      # minSize      number    No   Only include unspents that are at least this many satoshis.
      # segwit       boolean   No   Defaults to false, but is passed and set to true automatically from SDK version 4.3.0 forward.
      #
      # Response:
      # tx_hash           The hash of the unspent input
      # tx_output_n       The index of the unspent input from tx_hash
      # value             The value, in satoshis of the unspent input
      # script            Output script hash (in hex format)
      # redeemScript      The redeem script
      # chainPath         The BIP32 path of the unspent output relative to the wallet
      # confirmations     Number of blocks seen on and after the unspent transaction was included in a block
      # isChange          Boolean indicating this is an output from a previous spend originating on this wallet, and may be safe to spend even with 0 confirmations
      # instant           Boolean indicating if this unspent can be used to create a BitGo Instant transaction guaranteed against double spends
      # replayProtection  string Array of blockchains which this unspent will not be replayed on
      def unspents(wallet_id: default_wallet_id)
        call :get, '/wallet/' + wallet_id + '/unspents'
      end

      def create_transaction(wallet_id: default_wallet_id, params: {})
        call :post, '/wallet/' + wallet_id + '/createtransaction', params
      end

      # Sign Transaction
      #
      # transactionHex  string                  Yes   The unsigned transaction, in hex string form
      # unspents        array                   Yes   Array of unspents objects, which contain the chainpath and redeemScript.
      # keychain        keychain object         Yes   The decrypted keychain (object), with available xprv property.
      # signingKey      private   key (string)  No    For legacy safe wallets, the private key string.
      # validate        boolean                 No    Extra verification of signatures (which are always verified server-side), defaults to global configuration.

      def sign_transaction(wallet_id: default_wallet_id, params: {})
        call :post, '/wallet/' + wallet_id + '/signtransaction', params
      end

      def send_transaction(params: {})
        call :post, '/tx/send', params
      end

      ###############
      # Webhook APIs
      ###############
      # Adds a Webhook that will result in a HTTP callback at the specified URL from BitGo when events are triggered. There is a limit of 5 Webhooks of each type per wallet.
      #
      # type        string  (Required)  type of Webhook, e.g. transaction
      # url       string  (Required)  valid http/https url for callback requests
      # numConfirmations  integer (Optional)  number of confirmations before triggering the webhook. If 0 or unspecified, requests will be sent to the callback endpoint will be called when the transaction is first seen and when it is confirmed.
      def add_webhook(wallet_id: default_wallet_id, type:, url:, confirmations: 0)
        add_webhook_params = {
          type: type,
          url: url,
          numConfirmations: confirmations
        }
        call :post, '/wallet/' + wallet_id + '/webhooks', add_webhook_params
      end


      def remove_webhook(wallet_id: default_wallet_id, type:, url:)
        remove_webhook_params = {
          type: type,
          url: url
        }
        call :delete, '/wallet/' + wallet_id + '/webhooks', remove_webhook_params
      end

      def list_webhooks(wallet_id: default_wallet_id)
        call :get, '/wallet/' + wallet_id + '/webhooks'
      end

      ###############
      # Utilities (Via Bitgo Express API)
      ###############

      def encrypt(input:, password:)
        call :post, '/encrypt', { input: input, password: password }
      end

      def decrypt(input:, password: default_wallet_passphrase)
        call :post, '/decrypt', { input: input, password: password }
      end

      # Client-side function to verify that a given string is a valid Bitcoin Address. Supports both v1 addresses (e.g. “1…”) and P2SH addresses (e.g. “3…”).
      def verify_address(address:)
        verify_address_params = {
          address: address
        }
        call :post, '/verifyaddress', verify_address_params
      end

      ###############
      # Blockchain data (Via Bitgo Express API)
      ###############

      # Get Transaction Details

      def transaction(tx_hash)
        call :get, "/tx/#{tx_hash}"
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
          # request.add_field('Authorization', 'Bearer ' + @session_token)
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
