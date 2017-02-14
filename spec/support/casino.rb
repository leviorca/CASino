require 'active_support/core_ext/object/deep_dup'
require 'database_cleaner'

RSpec.configure do |config|
  DatabaseCleaner[:mongoid].strategy = :truncation , {:only => %w[casino_auth_token_tickets casino_login_attempts casino_login_tickets casino_proxy_granting_tickets casino_proxy_tickets casino_service_rules casino_service_tickets casino_ticket_granting_tickets casino_two_factor_authenticators casino_users]}
  DatabaseCleaner.start

  config.before do
    DatabaseCleaner.clean
    @base_config = CASino.config.deep_dup
  end

  config.after do
    DatabaseCleaner.clean
    CASino.config.clear
    CASino.config.merge! @base_config
  end
end
