module MyTagPlugin

  # A version of a page that represents a tag index.
  class TagPageGenerator < Jekyll::Generator
    safe true

    def generate(site)
      site.tags.keys.each do |tag|
        site.pages << TagPage.new(site, tag, site.tags[tag])
      end
    end
  end

  class TagPage < Jekyll::Page
    def initialize(site, tag, posts)
      @site = site
      @base = site.source
      @dir = tag
      @basename = 'index'
      @ext = '.html'
      @name = 'index.html'
      @data = {
        'tag_posts' => posts,
        'tag_name' => tag
      }
      data.default_proc = proc do |_, key|
        site.frontmatter_defaults.find(relative_path, :tags, key)
      end
    end
    def url_placeholders
      {
        :tag => @dir,
        :basename => basename,
        :output_ext => output_ext,
      }
    end
  end


end
