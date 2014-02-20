class LivepageConfig < Struct.new(:talk, :user)
  
  def to_json
    return JSON.pretty_generate(to_hash) if Rails.env.development?
    to_hash.to_json
  end

  def to_hash
    {
      # user
      user: user_details,
      initial_state: initial_state(user_details[:role]),
      statemachine: statemachine,
      # talk
      talk_id: talk.id,
      host: talk.user.name,
      title: talk.title,
      teaser: talk.teaser,
      session: talk.session,
      talk: { state: talk.state },
      starts_at: talk.starts_at.to_i,
      ends_at: talk.ends_at.to_i,
      # faye
      fayeClientUrl: PrivatePub.config[:server] + '/client.js',
      fayeUrl: PrivatePub.config[:server],
      subscription: subscription,
      # streams
      namespace: "t#{talk.id}",
      # misc
      fullname: user.name,
      user_id: user.id,
      handle: "u#{user.id}",
      role: role, # TODO remove in favor of user.role
      stream: "t#{talk.id}-u#{user.id}",
      streaming_server: Settings.rtmp.record
    }
  end

  def user_details
    @user_details ||= user.details_for(talk)
  end

  def initial_state(role)
    case role
    when :host then 'HostRegistering'
    when :guest then 'GuestRegistering'
    else 'Registering'
    end
  end

  def subscription
    PrivatePub.subscription channel: talk.public_channel
  end

  def statemachine_spec
    # events in 'Simple Past', states in 'Present Progressive'
    #
    # NOTE: 'PromotionDeclined' always leads to 'Listening'
    #
    # from-state         -> transition        -> to-state
    <<-EOF
      Registering        -> Registered        -> Waiting
      Waiting            -> TalkStarted       -> Listening
      Listening          -> MicRequested      -> ExpectingPromotion
      ExpectingPromotion -> Promoted          -> OnAir
      Listening          -> Promoted          -> AcceptingPromotion
      AcceptingPromotion -> PromotionAccepted -> OnAir
      AcceptingPromotion -> PromotionDeclined -> Listening
      OnAir              -> Demoted           -> Listening
      GuestRegistering   -> Registered        -> OnAir
      HostRegistering    -> Registered        -> HostOnAir
      *                  -> TalkEnded         -> Loitering
    EOF
  end
  
  def statemachine
    statemachine_spec.split("\n").map do |transition|
      from, name, to = transition.split('->').map(&:strip)
      { name: name, from: from, to: to }
    end
   end

  # TODO remove
  def role
    user.role_for(talk)
  end

end