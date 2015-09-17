require 'faraday'
require 'json'

require_relative 'models.rb'

class CollectionJSONMiddleware < Faraday::Middleware
  def initialize(app)
    @app = app
  end

  def call(env)
    env[:request_headers]["Accept"] = "application/vnd.collection+json"
    @app.call(env)
  end
end

class Client
  def initialize(url)
    @url = url
  end

  def get(url)
    response = connection.get(url)
    json = JSON.parse(response.body)
    Collection.new(json)
  end

  def delete(item)
    response = connection.delete(item.href)
    json = JSON.parse(response.body)
    Collection.new(json)
  end

  def update(item, template)
    response = connection.put(item.href) do |req|
      req.headers["Content-Type"] = "application/vnd.collection+json"
      req.body = template.to_json
    end
    json = JSON.parse(response.body)
    Collection.new(json)
  end

  def add_template(collection, template)
    response = connection.post(collection.href) do |req|
      req.headers["Content-Type"] = "application/vnd.collection+json"
      req.body = template.to_json
    end
    json = JSON.parse(response.body)
    Collection.new(json)
  end

  private

  def connection
    @connection ||= Faraday.new(@url) do |conn|
      conn.use CollectionJSONMiddleware
      conn.adapter Faraday.default_adapter
    end
  end
end
