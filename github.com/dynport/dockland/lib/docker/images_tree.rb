module Docker
  class ImagesTree
    attr_reader :images
    def initialize(images)
      @images = images
    end

    def parent_nodes
      @images.reject(&:parent)
    end

    def leave_nodes
      images_hash = images.inject({}) do |hash, image|
        hash[image.id] = image
        hash
      end

      images.each do |image|
        images_hash.delete(image.parent) if image.parent
      end

      images_hash.values
    end

    def to_digraph(base_url)
      lines = []
      parent_nodes.each do |parent|
        lines << %( base -> "#{shorten_id(parent.id)}" [style=invis];)
      end
      images.each do |image|
        lines += serialize_image(image, base_url)
      end
      lines << %(base [style=invisible];)
      "digraph docker {\n" + lines.sort.join("\n") + "\n}"
    end

    def serialize_image(image, base_url)
      label = [[shorten_id(image.id)] + image.tags].flatten.compact.reject { |s| s.to_s.strip.length == 0 }.join("\\n").strip

      out = [
        %( "#{shorten_id(image.id)}" [label="#{label.strip}", URL="#{base_url}/images/#{image.id}", target="image_#{shorten_id(image.id)}"];)
      ]
      if image.parent
        out << %(  "#{shorten_id(image.parent)}" -> "#{shorten_id(image.id)}" )
      end
      out
    end

    def shorten_id(id)
      id[0,8]
    end
  end
end
