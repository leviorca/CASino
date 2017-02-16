
class CASino::ProxyGrantingTicket
  include Mongoid::Document
  include Mongoid::Timestamps
  include CASino::ModelConcern::Ticket

  store_in collection: 'casino_proxy_granting_tickets'

  field :ticket,          type: String
  field :iou,             type: String
  field :pgt_url,         type: String

  index ticket: 1

  self.ticket_prefix = 'PGT'.freeze

  before_validation :ensure_iou_present

  validates :ticket, :iou, :pgt_url, presence: true
  validates :ticket, uniqueness: true
  validates :iou, uniqueness: true

  belongs_to :granter, polymorphic: true, index: true
  has_many :proxy_tickets, class_name: 'CASino::ProxyTicket', inverse_of: :proxy_granting_ticket, dependent: :destroy

  private
  def ensure_iou_present
    self.iou ||= create_random_ticket_string('PGTIOU')
  end
end
