@audio_format ||= 'ogg'
xml.instruct! 
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title @venue.title
    xml.description h @venue.description
    xml.link venue_url(@venue)
    xml.image do
      xml.url "#{request.protocol}#{request.host_with_port}#{@venue.image.url}"
      xml.title @venue.title
      xml.link venue_url(@venue)
    end
    #xml.tag! 'atom:link', rel: 'self', type: 'application/rss+xml', href: venue_talks_url(@venue, format: :rss)
    @venue.talks.each do |talk|
      if talk.archived?
        xml.item do
          xml.title talk.title
          xml.description h talk.description
          xml.pubDate talk.updated_at.to_s(:rfc822)
          xml.link venue_talk_url(@venue, talk)
          xml.guid venue_talk_url(@venue, talk)
          talk.media_links.each_pair do |k,v|
            xml.enclosure url: "http://voicerepublic.com#{v}", 
                          type: "audio/#{k}", 
                          length: talk.duration if k == @audio_format
          end
        end
      end
    end
  end
end
