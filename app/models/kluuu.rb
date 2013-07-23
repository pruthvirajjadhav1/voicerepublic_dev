# Attributes:
# * id [integer, primary, not null] - primary key
# * available_at_times [string] - TODO: document me
# * category_id [integer] - belongs to :category
# * charge_cents [integer, default=0] - TODO: document me
# * charge_type [string, default="free"] - TODO: document me
# * created_at [datetime, not null] - creation time
# * currency [string] - TODO: document me
# * description [text] - TODO: document me
# * published [boolean] - TODO: document me
# * title [string]
# * type [string] - TODO: document me
# * updated_at [datetime, not null] - last update time
# * user_id [integer] - belongs to :user
class Kluuu < Klu
  attr_accessible :klu_images_attributes
  
  CHARGE_TYPES = %w{free minute fix}
  
  has_many :bookmarks, :dependent => :destroy, :foreign_key => :klu_id
  has_many :klu_images, :foreign_key => :klu_id, :dependent => :destroy
  # because of STI in Klu - rateable_type will always be 'Klu'
  has_many :ratings, :as => :rateable, :dependent => :destroy 
  has_many :venues, :foreign_key => :host_kluuu_id, :dependent => :destroy
  
  # see base-class for base-validations
  validates_presence_of :charge_cents, :description, :category_id #, :currency  #, :currency
  validate :set_currency, :if => Proc.new { |k| k.charge_type != 'free' }
  validate :check_charge
  
  accepts_nested_attributes_for :klu_images, :allow_destroy => true
  
  monetize :charge_cents
  
  after_create :generate_notification  # defined in base-class
  
  
  def upcoming_venues
    self.venues.where("start_time > ?", Time.now)
  end
  
  def set_currency
    unless self.user.balance_account.nil?
      self.currency = self.user.balance_account.currency
    else
      self.errors.add(:currency, I18n.t('model_kluuu.no_account', :default => 'You got to create an balance account before You can charge for your KluuUs'))
    end
  end
  
  def check_charge
    if charge_type == 'minute'
      unless charge_cents < 501 || charge_cents > 9
        self.errors.add(:charge_cents, I18n.t('model_kluuu.charge_per_minute_error', :default => "Minimum 10 and maximum 500"))
      end
    end
    if charge_type == 'fix'
      unless charge_cents < 5001 || charge_cents > 99
        self.errors.add(:charge_cents, I18n.t('model_kluuu.charge_fixed_error', :default => "Minimum 100 and maximum 5000"))
      end
    end
    if charge_type == 'free'
      if charge_cents > 0 || charge_cents < 0
        self.errors.add(:charge_cents, I18n.t('model_kluuu.charge_free_error', :default => "You should leave the amount at zero if this is a free kluuu"))
      end
    end
  end
    
end
