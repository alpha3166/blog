FROM jekyll/jekyll
RUN echo "source 'https://rubygems.org'" > Gemfile && \
    echo "gem 'github-pages', group: :jekyll_plugins" >> Gemfile && \
    echo "gem 'webrick'" >> Gemfile && \
    bundle install && \
    rm -f Gemfile Gemfile.lock
EXPOSE 4000
WORKDIR /srv/jekyll/docs
CMD ["bundle", "exec", "jekyll", "serve", "--incremental", "--host", "0.0.0.0", "--baseurl", ""]
