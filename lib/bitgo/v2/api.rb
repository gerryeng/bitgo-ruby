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
        COIN_BCH  = 'bch',  # Bitcoin Cash Production  Production
        COIN_TBCH = 'tbch', # Bitcoin Cash Testnet  Test
        COIN_XRP  = 'xrp',  # Ripple Production Production
        COIN_TXRP = 'txrp', # Ripple Testnet  Test
        COIN_LTC  = 'ltc',  # Litecoin Production Production
        COIN_TLTC = 'tltc', # Litecoin Testnet4 Test
        COIN_ZEC  = 'zec',  # Zcash Production
        COIN_TZEC = 'tzec', # Zcash Testnet
        COIN_DASH  = 'dash',  # DASH Production
        COIN_TDASH = 'tdash', # DASH Testnet
        COIN_XLM  = 'xlm',  # Stellar Production
        COIN_TXLM = 'txlm', # Stellar Testnet
        COIN_RMG  = 'rmg',  # Royal Mint Gold Production  Production
        COIN_TRMG = 'trmg', # Royal Mint Gold Testnet Test
      ]

      def initialize(end_point = LIVE, proxy_url: nil)
        @end_point = end_point
        @proxy_url = proxy_url
      end

      ###############
      # Keychains API
      ###############

      # Query Parameters
      # Parameter    Type       Required   Description
      # limit        Integer    No         Max number of results in a single call. Defaults to 25.
      # prevId       String     No         Continue iterating (provided by nextBatchPrevId in the previous list)
      def list_keychains(coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/key", params
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

      def get_keychain(keychain_id:, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/key/#{keychain_id}"
      end

      ###############
      # Wallets API
      ###############

      # Query Parameters
      # Parameter   Type      Required   Description
      # limit       Integer   No         Max number of results in a single call. Defaults to 25.
      # prevId      String    No         Continue iterating wallets from this prevId as provided by nextBatchPrevId in the previous list
      # allTokens   Boolean   No         Gets details of all tokens associated with this wallet. Only valid for eth/teth
      def list_wallets(coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/wallet", params
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
      #
      # Query Parameters
      # Parameter   Type       Required   Description
      # allTokens   Boolean    No         Gets details of all tokens associated with this wallet. Only valid for eth/teth
      def get_wallet(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(COIN_BTC)
        call :get, "/#{coin}/wallet/#{wallet_id}", params
      end

      # Response:
      # id            The outpoint of the unspent (txid:vout)
      # address       The address that owns this unspent
      # value         Value of the unspent in satoshis
      # valueString   Value of the unspent in satoshis in string format
      # blockHeight   The height of the block that created this unspent
      # date          The date the unspent was created
      # wallet        The id of the wallet the unspent is in
      # fromWallet    The id of the wallet the unspent came from (if it was sent from a BitGo wallet you’re a member on , null otherwise)
      # chain         The address type and derivation path of the unspent (0 = normal unspent, 1 = change unspent, 10 = segwit unspent, 11 = segwit change unspent)
      # index         The position of the address in this chain’s derivation path
      # redeemScript  The script defining the criteria to be satisfied to spend this unspent
      # isSegwit      A flag indicating whether this is a segwit unspent
      # witnessScript
      #
      # Query Parameters
      # Parameter   Type     Required   Description
      # prevId      String   No         Continue iterating wallets from this prevId as provided by nextBatchPrevId in the previous list
      # minValue    Integer  No         Ignore unspents smaller than this amount of satoshis
      # maxValue    Integer  No         Ignore unspents larger than this amount of satoshis
      # minHeight   Integer  No         Ignore unspents confirmed at a lower block height than the given minHeight
      # minConfirms Integer  No         Ignores unspents that have fewer than the given confirmations
      def unspents(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/unspents", params
      end

      def create_transaction(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :post, "/#{coin}/wallet/#{wallet_id}/tx/build", params
      end

      alias_method :build_transaction, :create_transaction

      def sign_transaction(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        params[:walletPassphrase] ||= default_wallet_passphrase
        call :post, "/#{coin}/wallet/#{wallet_id}/signtx", params
      end

      def send_transaction(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :post, "/#{coin}/wallet/#{wallet_id}/tx/send", params
      end

      # Gets a list of addresses which have been instantiated for a wallet using the New Address API.
      # Query Parameters
      # Parameter   Type     Required   Description
      # limit       Number   No         The maximum number of addresses to be returned.
      # prevId      String   No         Continue iterating (provided by nextBatchPrevId in the previous list)
      # sortOrder   Number   No         Order the addresses by creation date. -1 is newest first, 1 is for oldest first.
      def list_wallet_addresses(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/addresses", params
      end

      # Query Parameters
      # Parameter   Type     Required   Description
      # prevId      String   No         Continue iterating (provided by nextBatchPrevId in the previous list result)
      # allTokens   Boolean  No         Gets details of all token transactions associated with this wallet. Only valid for eth/teth.
      def list_wallet_transactions(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/tx", params
      end

      def get_wallet_transaction(tx_id, wallet_id: default_wallet_id, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/tx/#{tx_id}"
      end

      # Query Parameters
      # Parameter   Type     Required   Description
      # prevId      String   No         Continue iterating from this prevId (provided by nextBatchPrevId in the previous list)
      # allTokens   Boolean  No         Gets transfers of all tokens associated with this wallet. Only valid for eth/teth.
      def list_wallet_transfers(wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/transfer", params
      end

      def get_wallet_transfer(tx_id_or_transfer_id, wallet_id: default_wallet_id, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/transfer/#{tx_id_or_transfer_id}"
      end

      # Parameter     Type      Description
      # comment       String    comment to add
      # id            String    transfer_id
      def add_comment(transfer_id, wallet_id: default_wallet_id, coin: COIN_BTC, params: {})
        validate_coin!(coin)
        call :post, "/#{coin}/wallet/#{wallet_id}/transfer/#{transfer_id}/comment", params
      end

      def create_address(wallet_id: default_wallet_id, coin: COIN_BTC, label: nil)
        validate_coin!(coin)
        call :post, "/#{coin}/wallet/#{wallet_id}/address", {label: label}
      end

      alias :add_address :create_address

      def send_coins(wallet_id: default_wallet_id,
        wallet_passphrase: default_wallet_passphrase,
        address:,
        amount:,
        min_value: nil,
        max_value: nil,
        # sequence_id: nil,
        # fee_rate: nil,
        # max_fee_rate: nil,
        min_confirms: nil,
        enforce_min_confirms_for_change: nil,
        # target_wallet_unspents: nil,
        # fee_tx_confirm_target: nil,
        message: nil,
        comment: nil,
        coin: nil,
        memo: nil # {type: 'id', value: '1'}
      )

        params = {
          walletPassphrase: wallet_passphrase,
          address: address,
          amount: amount
        }

        validate_coin!(coin)

        # API v1 uses message, API v2 uses comment for sendmany, but send_coins in API v2 uses
        # message again (for non-UTXO based coin support)
        if (message && comment) and (message != comment)
          raise "message: #{message} and comment: #{comment} are both present, but they differ"
        end
        message = message || comment

        params[:minValue] = min_value unless min_value.nil?
        params[:maxValue] = max_value unless max_value.nil?
        # params[:sequenceId] = sequence_id unless sequence_id.nil?
        # params[:feeRate] = fee_rate unless fee_rate.nil?
        # params[:maxFeeRate] = max_fee_rate unless max_fee_rate.nil?
        params[:minConfirms] = min_confirms unless min_confirms.nil?
        params[:enforceMinConfirmsForChange] = enforce_min_confirms_for_change unless enforce_min_confirms_for_change.nil?
        # params[:targetWalletUnspents] = target_wallet_unspents unless target_wallet_unspents.nil?
        # params[:feeTxConfirmTarget] = fee_tx_confirm_target unless fee_tx_confirm_target.nil?
        params[:message] = message unless message.nil?
        params[:memo] = memo unless memo.nil?

        call :post, "/#{coin}/wallet/#{wallet_id}/sendcoins", params
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
        comment: nil,
        coin: nil,
        memo: nil # {type: 'id', value: '1'}
      )

        params = {
          walletPassphrase: wallet_passphrase,
          recipients: recipients
        }

        validate_coin!(coin)

        # API v1 uses message, API v2 uses comment
        if (message && comment) and (message != comment)
          raise "message: #{message} and comment: #{comment} are both present, but they differ"
        end
        comment = comment || message

        params[:minValue] = min_value unless min_value.nil?
        params[:maxValue] = max_value unless max_value.nil?
        params[:sequenceId] = sequence_id unless sequence_id.nil?
        params[:feeRate] = fee_rate unless fee_rate.nil?
        params[:maxFeeRate] = max_fee_rate unless max_fee_rate.nil?
        params[:minConfirms] = min_confirms unless min_confirms.nil?
        params[:enforceMinConfirmsForChange] = enforce_min_confirms_for_change unless enforce_min_confirms_for_change.nil?
        params[:targetWalletUnspents] = target_wallet_unspents unless target_wallet_unspents.nil?
        params[:feeTxConfirmTarget] = fee_tx_confirm_target unless fee_tx_confirm_target.nil?
        params[:comment] = comment unless comment.nil?
        params[:memo] = memo unless memo.nil?

        call :post, "/#{coin}/wallet/#{wallet_id}/sendmany", params
      end

      # Accelerate Transaction (BitGo Express)
      #
      # Parameter                     Type     Required  Description
      # cpfpTxIds                     Array    Yes       Array of string txids of the transactions to bump
      # walletPassphrase              String   Yes       Passphrase to decrypt the wallet’s private key.
      # cpfpFeeRate                   Integer  Yes       Desired effective feerate of the bumped transactions and the CPFP transaction in satoshi per kilobyte
      # maxFee                        Integer  Yes       Maximum allowed fee for the CPFP transaction in satoshi
      #
      # Response
      #
      # Returns the newly created transaction description object.
      #
      # Field    Description
      # transfer New transfer object
      # txid     Unique transaction identifier
      # tx       Encoded transaction hex (or base64 for XLM)
      # status   Transfer status: Enum:"signed" "signed (suppressed)" "pendingApproval"
      #
      # https://www.bitgo.com/api/v2/#operation/express.wallet.acceleratetx
      def accelerate_transaction(wallet_id: default_wallet_id,
        wallet_passphrase: default_wallet_passphrase,
        cpfp_tx_ids:,
        cpfp_fee_rate:,
        max_fee:,
        coin: COIN_BTC
      )
        validate_coin!(coin)

        cpfp_tx_ids = case cpfp_tx_ids
        when Array
          if cpfp_tx_ids != 1
            raise ArgumentError, "cpfp_tx_ids accepts only a single txid at this stage"
          end
          cpfp_tx_ids
        when String
          [cpfp_tx_ids]
        else
          raise ArgumentError, "cpfp_tx_ids must be a txid string or an array with a single txid"
        end

        params = {
          walletPassphrase: wallet_passphrase,
          cpfpTxIds: cpfp_tx_ids,
          cpfpFeeRate: cpfp_fee_rate,
          maxFee: max_fee,
          recipients: [], # This is not documented and passed as is: [] internally on a bitgo branch
        }

        call :post, "/#{coin}/wallet/#{wallet_id}/acceleratetx", params
      end

      def fee_estimate(num_blocks: 2, coin: COIN_BTC)
        validate_coin!(coin)

        params = {
          numBlocks: num_blocks,
        }

        call :get, "/#{coin}/tx/fee", params
      end

      ###############
      # Webhook APIs
      ###############

      # Adds a Webhook that will result in a HTTP callback at the specified URL from BitGo when events are triggered. There is a limit of 5 Webhooks of each type per wallet.
      #
      # type        string  (Required)  type of Webhook, e.g. transaction
      # url       string  (Required)  valid http/https url for callback requests
      # numConfirmations  integer (Optional)  number of confirmations before triggering the webhook. If 0 or unspecified, requests will be sent to the callback endpoint will be called when the transaction is first seen and when it is confirmed.
      def add_webhook(wallet_id: default_wallet_id, type:, url:, confirmations: 0, coin: COIN_BTC)
        validate_coin!(coin)
        add_webhook_params = {
          type: type,
          url: url,
          numConfirmations: confirmations
        }
        call :post, "/#{coin}/wallet/#{wallet_id}/webhooks", add_webhook_params
      end


      def remove_webhook(wallet_id: default_wallet_id, type:, url:, coin: COIN_BTC)
        validate_coin!(coin)
        remove_webhook_params = {
          type: type,
          url: url
        }
        call :delete, "/#{coin}/wallet/#{wallet_id}/webhooks", remove_webhook_params
      end

      def list_webhooks(wallet_id: default_wallet_id, coin: COIN_BTC)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/webhooks"
      end

      ###############
      # Blockchain data (Via Bitgo Express API)
      ###############

      # Get Transaction Details

      def transaction(tx_hash, coin: COIN_BTC, wallet_id: default_wallet_id)
        validate_coin!(coin)
        call :get, "/#{coin}/wallet/#{wallet_id}/tx/#{tx_hash}"
      end

    private

      def validate_coin!(coin)
        fail "param coin must be one of #{COINS.join(', ')}" unless COINS.include?(coin)
      end
    end
  end
end
