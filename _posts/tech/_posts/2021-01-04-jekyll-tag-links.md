---
layout: post
title:  "How I made the tag links"
author: srang
date:   2021-01-04
categories: tech
tags:
  - code
  - website
  - jekyll
---

## Intro

This is the first post about how I put together things for this site, and
hopefully, it is helpful for those new to Jekyll, GitHub Pages, or even web
development in general. Full disclosure, I don't consider myself a professional
web developer, but I have developed enterprise applications in a professional
capacity in the past (mostly back-end Java). For those who are everyday
front-end web developers, this side of the blog may be fairly boring, but
there's always football.

## Splitting into Categories

This all started, well, when I started the site. I had a couple of football
blog posts and wanted to play with the Jekyll tag/category system. The first
thing I wanted to do was figure out how to organize the blog splitting it into
football stuff and tech stuff. For that, I started with [Jekyll
categories](https://jekyllrb.com/docs/posts/#categories). I also wanted to show
separate pages for each category. To accomplish this, I created a custom
[`_include`](https://jekyllrb.com/docs/includes/) for post listings that expects
a `posts` variable is populated with - you guessed it - POSTS! This template
ensures a consistent look-and-feel anywhere I wanted to list posts.

`_includes/post_item.html`
{% highlight html linenos %}
{% raw %}
{%- if include.posts -%}
<ul class="post-list">
  {% for post in include.posts %}
    <li>
      {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
        <h3>
          <a class="post-link" href="{{ post.url | relative_url }}">
            {{ post.title | escape }}
          </a>
        </h3>
        <span class="post-meta">{{ post.date | date: date_format }}</span>
        {%- if site.data.config.show_excerpts -%}
        {{ post.excerpt }}
      {%- endif -%}
    </li>
  {% endfor %}
</ul>
{%- else -%}
<h2>No posts found :sob:</h2>
{%- endif -%}
{% endraw %}
{% endhighlight %}

Using the template simplified my category landing pages to look like this:

`football.html`
{% highlight html linenos %}
{% raw %}
<h1 class="post-list-heading">NFL Posts</h1>
{% include post_item.html posts=site.categories.football %}
{% endraw %}
{% endhighlight %}


## Adding and Showing Post Tags

Next, I wanted to further organize posts within each category, which made sense
to do with [Jekyll Tags](https://jekyllrb.com/docs/posts/#tags). I started
simple, just trying to show the tags on the page. I will admit I fell into a
deep dark hole around theming, and custom CSS/SASS, but I'll leave that for a
different post. Showing the tag looked like this:

`_includes/tag_list.html`
{% highlight html linenos %}
{% raw %}
{% if include.post.tags.size > 0 %}
  <div class="tag-list">
      {% for tag in include.post.tags %}
        <span class="post-tag">{{ tag }}</span>
      {% endfor %}
  </div>
{% endif %}
{% endraw %}
{% endhighlight %}

## Linking and Listing Posts by Tag

I had everything I wanted until I realized how nice it would be to be able to
click the tag and see other posts with that tag. This is where things got
surprisingly complicated (for me at least, feel free to leave feedback in the
[repo](github.com/srang/samuelrang.com)).

### Writing a Custom Plugin

>*NOTE*: It's important to know that up to this point, I'd been using the
`github-pages` gem for building and serving the site, as I use GitHub Pages to
host the site. Using GitHub Pages to host a Jekyll site has [designed
limitations]() for security reasons (it's hard to fault them since it's a very
nice, free service).  One of those limitations is around plugin usage,
specifically automatically deployed GitHub Pages Jekyll sites only allow a
specific list of [whitelisted plugins](https://pages.github.com/versions/).
What I didn't realize is that the `github-pages` gem [enforces
this](https://github.com/github/pages-gem/blob/bd1018072aab370ddf63aa9c3938867e2133ac80/lib/github-pages/configuration.rb#L45-L70),
_even in a local development environment_, making it impossible to load a custom
plugin. I chased my tail for longer than I care to disclose, trying to figure
out what was going on. Switching back to the `jekyll` gem for building solved
my problem.

After navigating a circuitous journey of blogs, I found that what I was trying
to do is a good use case for a custom plugin. *In fact*, this is almost the
exact use-case they demonstrate in the [Generator
Sample](https://jekyllrb.com/docs/plugins/generators/), just swapping out
`category` for `tag`:

{% highlight ruby linenos %}
{% raw %}
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
{% endraw %}
{% endhighlight %}

This plugin has two custom classes, a Generator and a Page. The
`TagPageGenerator` iterates through all the Tags in the Site and generates a
new `TagPage` for each, passing in the Tag and all Posts with that Tag.
Generators are automatically run as the site is built. The `TagPage` assigns
the array of posts and the name of the tag to named variables in the Page so
they can be easily accessed via `page.tag_posts` and `page.tag_name`,
respectively.

>For those with a keen eye, you may notice another small tweak. I had trouble
with the iteration from the official Jekyll example code: `site.tags.each do
|category, posts|` left the `posts` variable empty. Instead, I ended up
iterating over `site.keys` and fetching the posts in the loop with
`site.tags[tag]`.

### Building and Deploying the Site

To use my new custom plugin, I needed to switch to manually building and
deploying the site, since I could no longer let GitHub automagically do that.
There are lots of posts and strategies out there, but I landed on [this
one](https://surdu.me/2020/02/04/jekyll-git-hook.html) using pre-push git
hooks:

`.git/hooks/pre-push`
{% highlight bash linenos %}
{% raw %}
#!/bin/sh

# If any command fails in the below script, exit with error
set -e

# Set the name of the folder that will be created in the parent
# folder of your repo folder, and which will temporarily
# hold the generated content.
TEMP_FOLDER="_gh-pages-temp"
MASTER_BRANCH=main
DEPLOY_BRANCH=gh-pages

# Make sure our main code runs only if we push the master branch
if [ "$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)" == $MASTER_BRANCH ]; then
	# Store the last commit message from master branch
	last_message=$(git show -s --format=%s $MASTER_BRANCH)

	# Build our Jekyll site
	JEKYLL_ENV=production bundle exec jekyll build

	# Move the generated site in our temp folder
	mv _site ../${TEMP_FOLDER}

	# Checkout the gh-pages branch and clean it's contents
	git checkout $DEPLOY_BRANCH
	rm -rf *

	# Copy the site content from the temp folder and remove the temp folder
	cp -r ../${TEMP_FOLDER}/* .
	rm -rf ../${TEMP_FOLDER}

	echo "Commiting to $DEPLOY_BRANCH"
	# Commit and push our generated site to GitHub
	git add -A
	git commit -m "Built \`$last_message\`"
	git push

	# Go back to the master branch
	git checkout $MASTER_BRANCH
else
	echo "Not $MASTER_BRANCH branch. Skipping build"
fi
{% endraw %}
{% endhighlight %}

### Showing the Pages

Now that I had my site up-and-running with the custom plugin, I needed to
create a new layout for the pages the plugin generates, defined in `_layouts`
as:

`_layouts/tag_page.html`
{% highlight html linenos %}
{% raw %}
---
layout: default
---
<h1 class="post-list-heading">
  <code>{{ page.tag_name }}</code> Posts
</h1>
{% include post_item.html posts=page.tag_posts %}
{% endraw %}
{% endhighlight %}

This is almost identical to my `football.html` category page discussed earlier
(yay reusable code). To use this layout for a generated `TagPage`, I configured
the page defaults in my `_config.yml`, specifying the layout as `tag_page`:

`_config.yml`
{% highlight yaml linenos %}
{% raw %}
defaults:
  - scope:
      type: tags
    values:
      layout: tag_page
      permalink: tags/:tag/
{% endraw %}
{% endhighlight %}

At this point, the site is building and deploying and the plugin is generating new pages
at build time using the new layout for every tag in the site. The only problem is _there's
no way to get to the pages!_ Easy enough to fix. I tweaked the `post_item` code that we've
been so wonderfully reusing to change the tags to links:

`_includes/tag_list.html`
{% highlight html linenos %}
{% raw %}
{% if include.post.tags.size > 0 %}
  <div class="tag-list">
    {% for tag in include.post.tags %}
      <a href="{{ "/tags/" | append: tag | relative_url }}" class="post-tag">{{ tag }}</a>
    {% endfor %}
  </div>
{% endif %}
{% endraw %}
{% endhighlight %}

And voila! My tags now are clickable links that list all other posts with the
tag!

## Conclusion

This simple feature turned out to be surprisingly challenging, which means it
was a lot of fun. Hopefully this post will be helpful to others, as well! Feel
free to checkout the website [source code](github.com/srang/samuelrang.com)
and/or open an issue with questions or feedback.
