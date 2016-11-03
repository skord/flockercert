FROM python:2.7.12
RUN pip install https://clusterhq-archive.s3.amazonaws.com/python/Flocker-1.14.0-py2-none-any.whl
RUN apt-get update && apt-get -y install ruby-full && apt-get clean
RUN gem install bundler
ADD Gemfile Gemfile.lock /app/
WORKDIR /app
RUN bundle install
ADD . /app
EXPOSE 9292
ENV RACK_ENV=production
CMD ["rackup","-o","0.0.0.0","-p","9292"]
