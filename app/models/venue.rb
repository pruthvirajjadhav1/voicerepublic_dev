# Attributes:
# * id [integer, primary, not null] - primary key
# * created_at [datetime, not null] - creation time
# * description [text] - TODO: document me
# * duration [integer] - TODO: document me
# * featured_from [datetime] - TODO: document me
# * image_content_type [string] - Paperclip for image
# * image_file_name [string] - Paperclip for image
# * image_file_size [integer] - Paperclip for image
# * image_updated_at [datetime] - Paperclip for image
# * start_time [datetime] - TODO: document me
# * teaser [text] - TODO: document me
# * title [string]
# * updated_at [datetime, not null] - last update time
# * user_id [integer] - belongs to :user
class Venue < ActiveRecord::Base

  LIVE_TOLERANCE          = 5.minutes
  STREAMER_CONFIG         = Settings.rtmp
  RECORDINGS_PATH         = "#{Rails.root}/public/system/recordings"
  RECORDINGS_ARCHIVE_PATH = "#{Rails.root}/public/system/recordings_raw_archive"

  acts_as_taggable

  attr_accessible :title, :teaser, :description, :events_attributes, :tag_list

  belongs_to :user

  has_many :articles, -> { order "created_at DESC" }, :dependent => :destroy
  has_many :events, :dependent => :destroy, :inverse_of => :venue
  has_many :talks, :dependent => :destroy, :inverse_of => :venue

  has_many :participations, :dependent => :destroy
  has_many :users, :through => :participations

  validates :title, :teaser, :description, :tag_list, :presence => true

  before_save :clean_taglist # prevent vollpfosten from adding hash-tag to tag-names

  accepts_nested_attributes_for :events, :reject_if => proc { |attrs| attrs['start_time'].blank? }

  scope :of_user,           proc { |user| where(:user_id => user.id) }
  scope :featured,          proc { where('featured_from <= ?', Time.now.in_time_zone).
                                     order('featured_from DESC') }
  scope :not_past,          proc { joins(:events).merge(Event.not_past) }
  scope :upcoming_first,    proc { joins(:events).merge(Event.upcoming_first) }

  # start_time, duration, start_in_seconds wil return nil if no current_event
  delegate :start_time, :duration, :start_in_seconds, to: :current_event, allow_nil: true

  attr_accessible :image
  has_attached_file :image,
    :styles => { :medium => '242x145>', :thumb => "100x100>" },
    :default_url => "/images/:style/missing.png"

  define_index do
    indexes title, :as => :title, :sortable => true
    indexes taggings.tag.name, :as => :tags
    indexes events.title, :as => :event_title
  end

  # returns nil if no current or upcoming event
  def current_event
    events.not_past.upcoming_first.first
  end

  def reload_time
    return false if current_event.nil?
    (start_time.in_time_zone - Time.now.in_time_zone) - LIVE_TOLERANCE + rand * 3.0
  end

  def live?
    return false if current_event.nil? || current_event.end_at.present?
    start_time <= Time.now.in_time_zone + LIVE_TOLERANCE
  end

  def past?
    current_event.nil? || current_event.end_at.present?
  end
  alias_method :timed_out?, :past?

  def user_participates?(participant)
    users.include?(participant)
  end

  def user_attends?(user)
    attendees.include?(user)
  end

  def attendees
    [user] + users
  end

  def attendies
    #self.klus.collect { |k| k.user }.push(self.host_kluuu.user)
    [ user ]
  end

  # this is rendered as json in venue/venue_show_live
  def details_for(user)
    {
      streamId: "v#{id}-e#{current_event.id}-u#{user.id}",
      channel: story_channel,
      role: (self.user == user) ? 'host' : 'participant',
      storySubscription: PrivatePub.subscription(channel: story_channel),
      backSubscription: PrivatePub.subscription(channel: back_channel),
      chatSubscription: PrivatePub.subscription(channel: channel_name),
      streamer: (current_event.record ? STREAMER_CONFIG['recordings'] : STREAMER_CONFIG['discussions'])
    }
  end

  # the event channel propagates events, which get replayed on join
  def story_channel
    "/story/v#{id}e#{current_event.id}"
  end

  # the back channel propagates events, which don't get replayed
  def back_channel
    "/back/v#{id}e#{current_event.id}"
  end

  def chat_name
    "vgc-#{id}-#{current_event.id}"
  end

  def channel_name
    "/chatchannel/vgc-#{self.id}e#{current_event.id}"
  end

  def channel_host_info
    "/chatchannel/host-info/vgc-#{self.id}"
  end

  class << self

    def upcoming
      Venue.where("start_time > ?", Time.now - 1.hour).order("start_time ASC").limit(1).first
    end

    def one_day_ahead
      venues = Venue.where("start_time < ? AND start_time > ?", Time.now + 24.hours, Time.now + 23.hours)
    end

    def two_hour_ahead
      venues = Venue.where("start_time < ? AND start_time > ?", Time.now + 120.minutes, Time.now + 60.minutes )
    end

  end

  private

  def clean_taglist
    self_tag_list = tag_list.map { |t| t.tr_s(' ', '_').gsub('#', '') }
  end

end
