module Bitgo
  module V2

    class Api < Bitgo::V1::Api

      attr_accessor :session_token

      TEST = 'https://test.bitgo.com/api/v2'
      LIVE = 'https://www.bitgo.com/api/v2'
      EXPRESS = 'http://127.0.0.1:3080/api/v2'

      COINS = [
        COIN_BTC  = 'btc',  # Bitcoin Production  Production
        COIN_TBTC = 'tbtc', # Bitcoin Testnet3  Test
        COIN_ETH  = 'eth',  # Ethereum Production Production
        COIN_TETH = 'teth', # Ethereum Kovan Testnet  Test
        COIN_XRP  = 'xrp',  # Ripple Production Production
        COIN_TXRP = 'txrp', # Ripple Testnet  Test
        COIN_LTC  = 'ltc',  # Litecoin Production Production
        COIN_TLTC = 'tltc', # Litecoin Testnet4 Test
        COIN_RMG  = 'rmg',  # Royal Mint Gold Production  Production
        COIN_TRMG = 'trmg', # Royal Mint Gold Testnet Test
      ]

      def initialize(end_point = LIVE)
        @end_point = end_point
      end

      ###############
      # Keychains API
      ###############

      def list_keychains(coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/keychain"
      end

      # Bitgo express function
      # Client-side function to create a new keychain.
      # Optionally, a single parameter, 'seed’, may be provided which uses a deterministic seed to create your keychain. The seed should be an array of numbers at least 32 elements long. Calling this function with the same seed will generate the same BIP32 keychain.
      def create_keychain(seed: nil, coin: COIN_BTC)
        validate_coin!(coin)
        if seed.present?
          seed.scan(/../).map(&:hex)
          [seed].pack('H*').unpack('C*')
          seed_arr = [seed].pack('H*').bytes.to_a
          call :post, "/#{coin}/keychain/local", { seed: seed_arr }
        else
          call :post, "/#{coin}/keychain/local"
        end
      end

      def add_keychain(xpub:, encrypted_xprv:, coin: COIN_BTC)
        validate_coin!(coin)
        call :post, "/#{coin}/keychain", { xpub: xpub, encrypted_xprv: encrypted_xprv }
      end

      def create_bitgo_keychain(coin: COIN_BTC)
        validate_coin!(coin)
        call :post, "/#{coin}/keychain/bitgo"
      end

      ###############
      # Wallets API
      ###############

      def list_wallets(coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet"
      end

      # label: String  Yes Human-readable name for the wallet.
      # passphrase:  String  Yes Passphrase to decrypt the wallet’s private key.
      # userXpub:  String  No  Optional xpub to be used as the user key.
      # backupXpub:  String  No  Optional xpub to be used as the backup key.
      # backupXpubProvider:  String  No  Optional key recovery service to provide and store the backup key.
      # enterprise:  String  No  ID of the enterprise to associate this wallet with.
      # disableTransactionNotifications: Boolean No  Will prevent wallet transaction notifications if set to true.
      def add_wallet(args = {})
        coin = args.delete(:coin) || COIN_BTC
        validate_coin!(coin)
        call :post, "/#{coin}/wallet", args
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
      def get_wallet(wallet_id:, coin: COIN_BTC)
        validate_coin!(COIN_BTC)
        call :get, "/#{coin}/wallet/#{wallet_id}"
      end

      # Gets a list of addresses which have been instantiated for a wallet using the New Address API.
      def list_wallet_addresses(wallet_id:, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/addresses"
      end

      def list_walllet_transactions(wallet_id:, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/tx"
      end

      def get_walllet_transaction(wallet_id:, txid:, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/tx/#{txid}"
      end

      def create_address(wallet_id:, coin: COIN_BTC)
        validate_coin!(coin)
        call :post, "/#{coin}/wallet/#{wallet_id}/address/"
      end

      alias :add_address :create_address

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

      def send_many(coin:, wallet_id:, recipients:, wallet_passphrase:,
        min_value: nil,
        max_value: nil,
        sequence_id: nil,
        fee_rate: nil,
        min_confirms: nil,
        enforce_min_confirms_for_change: nil,
        target_wallet_unspents: nil,
        fee_tx_confirm_target: nil
      )
        validate_coin!(coin)

        params = {
          walletPassphrase: wallet_passphrase,
          recipients: recipients
        }

        params[:min_value] = min_value unless min_value.nil?
        params[:max_value] = max_value unless max_value.nil?
        params[:sequence_id] = sequence_id unless sequence_id.nil?
        params[:fee_rate] = fee_rate unless fee_rate.nil?
        params[:min_confirms] = min_confirms unless min_confirms.nil?
        params[:enforce_min_confirms_for_change] = enforce_min_confirms_for_change unless enforce_min_confirms_for_change.nil?
        params[:target_wallet_unspents] = target_wallet_unspents unless target_wallet_unspents.nil?

        call :post, "/#{coin}/wallet/#{wallet_id}/sendmany", params
      end

      ###############
      # Webhook APIs
      ###############

      # Adds a Webhook that will result in a HTTP callback at the specified URL from BitGo when events are triggered. There is a limit of 5 Webhooks of each type per wallet.
      #
      # type        string  (Required)  type of Webhook, e.g. transaction
      # url       string  (Required)  valid http/https url for callback requests
      # numConfirmations  integer (Optional)  number of confirmations before triggering the webhook. If 0 or unspecified, requests will be sent to the callback endpoint will be called when the transaction is first seen and when it is confirmed.
      def add_webhook(wallet_id:, type:, url:, confirmations: 0, coin: COIN_BTC)
        validate_coin!(coin)
        add_webhook_params = {
          type: type,
          url: url,
          numConfirmations: confirmations
        }
        call :post, "/#{coin}/wallet/#{wallet_id}/webhooks", add_webhook_params
      end


      def remove_webhook(wallet_id:, type:, url:, coin: COIN_BTC)
        validate_coin!(coin)
        remove_webhook_params = {
          type: type,
          url: url
        }
        call :delete, "/#{coin}/wallet/#{wallet_id}/webhooks", remove_webhook_params
      end

      def list_webhooks(wallet_id:, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/webhooks"
      end

    private

      def validate_coin!(coin)
        fail "param coin must be one of #{COINS.join(', ')}" unless COINS.include?(coin)
      end
    end
  end
end
