require 'addressable/uri'

class CASino::ServiceTicket
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::Ticket

  store_in collection: 'casino_service_tickets'

  field :ticket,                    type: String
  field :service,                   type: String
  field :consumed,                  type: Mongoid::Boolean, default: false
  field :issued_from_credentials,   type: Mongoid::Boolean, default: false

  index ticket: 1

  self.ticket_prefix = 'ST'.freeze

  validates :ticket, :service, :consumed, :issued_from_credentials, presence: true

  belongs_to :ticket_granting_ticket, class_name: 'CASino::TicketGrantingTicket', index: true
  before_destroy :send_single_sign_out_notification, if: :consumed?
  has_many :proxy_granting_tickets, class_name: 'CASino::ProxyGrantingTicket', as: :granter, dependent: :destroy

  def self.cleanup_unconsumed
    self.delete_all({created_at: {'$lt' => CASino.config.service_ticket[:lifetime_unconsumed].seconds.ago}, consumed: false})
  end

  def self.cleanup_consumed
    self.destroy_all({consumed: true, '$or' => [{ticket_granting_ticket_id: nil}, {created_at: {'$lt' => CASino.config.service_ticket[:lifetime_consumed].seconds.ago}}]})
  end

  def self.cleanup_consumed_hard
    self.delete_all({created_at: {'$lt' => (CASino.config.service_ticket[:lifetime_consumed] * 2).seconds.ago}, consumed: true})
  end

  def service=(service)
    normalized_encoded_service = Addressable::URI.parse(service).normalize.to_str
    super(normalized_encoded_service)
  end

  def service_with_ticket_url
    service_uri = Addressable::URI.parse(self.service)
    service_uri.query_values = (service_uri.query_values(Array) || []) << ['ticket', self.ticket]
    service_uri.to_s
  end

  def expired?
    lifetime = if consumed?
      CASino.config.service_ticket[:lifetime_consumed]
    else
      CASino.config.service_ticket[:lifetime_unconsumed]
    end
    (Time.now - (self.created_at || Time.now)) > lifetime
  end

  private
  def send_single_sign_out_notification
    notifier = SingleSignOutNotifier.new(self)
    notifier.notify
    true
  end
end
