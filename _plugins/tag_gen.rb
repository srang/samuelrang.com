module ListByTagPlugin

  # A version of a page that represents a tag index.
  class TagPageGenerator < Jekyll::Generator
    safe true

    def generate(site)
      # Iterate through all tags in the site
      site.tags.keys.each do |tag|
        # Generate a new page using the class below with the tag and all posts
        # for the tag as arguments
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

      # Load data into the page object, accessed via page.tag_posts
      @data = {
        'tag_posts' => posts,
        'tag_name' => tag
      }

      # Set default frontmatter
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
