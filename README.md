Bitgo Ruby Gem
===============

Lightweight wrapper of Bitgo and Bitgo Express REST API.

BitGo Documentation: https://www.bitgo.com/api/

Installation
===============

	gem install bitgo


### Usage ###

	# Endpoints
	end_point = Bitgo::V1::Api::TEST
	# end_point = Bitgo::V1::Api::LIVE
	# end_point = Bitgo::V1::Api::EXPRESS

	# Setup an api instance
	api = Bitgo::V1::Api.new(end_point)
	api.session_token = "your session token"


### User API ###

	api.session_info
	api.login(email: 'xx', password: 'xx', otp: 'xx')
	api.logout
	api.send_otp(send_sms: false)
	api.session_information
	api.lock
	api.unlock(otp: 'xx', duration_seconds: 600)

### Keychains API ###

	api.list_keychains
	api.create_keychains(seed)
	api.add_keychain(xpub: 'xx', encrypted_xprv: 'xx')
	api.create_bitgo_keychain


### Address Labels API ###

	api.list_labels
	api.list_labels_for_wallet(wallet_id: 'xx')
	api.set_label(wallet_id: 'xx', address: 'xx', label: 'xx')
	api.delete_label(wallet_id: 'xx', address: 'xx')

### Wallets API ###

	api.list_wallets
	api.simple_create_wallet(passphrase: 'xx', label: 'xx') # Bitgo express
	api.add_wallet(label: 'xx', m: 2, n: 3, keychains: 'xxx', enterprise: 'xx')
	api.get_wallet(wallet_id: 'xx')
	api.list_wallet_addresses(walet_id: 'xx')
	api.create_address(wallet_id: 'xx', chain: 'xx')
	api.send_coins_to_address(address: 'address', amount: 'xx', wallet_passphrase: 'xx')

### Webhooks API ###

	api.add_webhook(wallet_id: 'xx', type: 'xx', url: 'xx', confirmations: 'xx')
	api.remove_webhook(wallet_id: 'xx', type: 'xx', url: 'xx')
	api.list_webhooks(wallet_id: 'xx')

### Utilities API (Via Bitgo Express) ###

	api.encrypt(input: 'string to encrypt, usually xprv', password: 'password to encrypt')
	api.decrypt(input: 'string to decrypt, output of encrypt()', password: 'password to decrypt')
	api.verify_address(address: 'xx')