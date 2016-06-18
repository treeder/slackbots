FROM iron/ruby:dev

WORKDIR /bot
ADD Gemfile* /bot/
RUN bundle config --local build.nokogiri --use-system-libraries && bundle install

ADD . /bot/

ENTRYPOINT ["ruby", "guppy.rb"]
