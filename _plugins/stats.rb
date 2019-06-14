module Jekyll
  class DurationSum < Liquid::Tag
    def render(context)
      seconds = context.registers[:site].categories['podcast'].reduce(0) { |sum, episode|
        dur = episode.data['file_duration'].split(":").reverse.each_with_index.map{ |x,i| x.to_i * (60 ** i) }
        sum + dur.reduce(:+)
      }

      humanize seconds
    end

    def humanize secs
      [[60, :seconds], [60, :minutes], [24, :hours], [Float::INFINITY, :days]].map{ |count, name|
        if secs > 0
          secs, n = secs.divmod(count)
          "#{n.to_i} #{name}" unless n.to_i == 0
        end
      }.compact.reverse.join(' ')
    end
  end

  class EpisodesCount < Liquid::Tag
    def initialize(tag_name, text, tokens)
      super
      @name = text.strip
    end

    def render(context)
      episodes = context.registers[:site].categories['podcast']

      if @name != ""
        episodes.select! { |e| e.data['team'].include? @name }
      end

      episodes.size
    end
  end

end

Liquid::Template.register_tag('duration_sum', Jekyll::DurationSum)
Liquid::Template.register_tag('episodes_count', Jekyll::EpisodesCount)

