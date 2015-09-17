require 'uri'

class Collection
  attr_reader :version, :href, :links, :items, :queries, :template

  def initialize(json)
    collection = json.fetch("collection")

    @version = collection.fetch("version", nil)
    @href = collection.fetch("href", nil)
    @links = collection.fetch("links", []).map { |link| Link.new(link) }
    @items = collection.fetch("items", []).map { |item| Item.new(item) }
    @queries = collection.fetch("queries", []).map do |query|
      Query.new(query)
    end
    template = collection.fetch("template", nil)
    @template = Template.new(template) if template
  end

  def query(rel)
    queries.detect do |query|
      query.rel == rel
    end
  end
end

class Query
  attr_reader :rel, :href, :prompt, :data

  def initialize(attributes)
    @rel = attributes.fetch("rel")
    @href = attributes.fetch("href")
    @prompt = attributes.fetch("prompt")
    @data = attributes.fetch("data", []).map do |data|
      DataItem.new(data)
    end
  end

  def set(data, value)
    @values ||= Faraday::Utils::ParamsHash.new
    @values[data.name] = value
  end

  def to_url
    uri = URI.parse(href)
    uri.query = @values.to_query
    uri.to_s
  end
end

class Template
  attr_reader :prompt, :rel, :data

  def initialize(attributes)
    @prompt = attributes.fetch("prompt", nil)
    @data = attributes.fetch("data", []).map do |data|
      DataItem.new(data)
    end
  end

  def set(data, value)
    @values ||= {}
    @values[data.name] = value
  end

  def to_json
    {
      :template => {
        :data => data.map do |data|
          {
            :name => data.name,
            :value => @values[data.name],
          }
        end
      },
    }.to_json
  end
end

class Link
  def initialize(attributes)
    @attributes = attributes
  end

  def to_s
    "#{rel}: #{href}"
  end

  def [](key)
    @attributes[key]
  end

  def rel
    @attributes.fetch("rel")
  end

  def href
    @attributes.fetch("href")
  end
end

class Item
  attr_reader :href, :data, :links

  def initialize(attributes)
    @href = attributes.fetch("href")
    @data = attributes.fetch("data", []).map do |data|
      DataItem.new(data)
    end
    @links = attributes.fetch("links", []).map { |link| Link.new(link) }
  end

  def attribute(name)
    data.detect { |attribute| attribute.name == name }
  end
end

class DataItem
  def initialize(attributes)
    @attributes = attributes
  end

  def to_s
    "#{name}: #{value}"
  end

  def [](key)
    @attributes[key]
  end

  def name
    @attributes.fetch("name")
  end

  def value
    @attributes.fetch("value", nil)
  end

  def prompt
    @attributes.fetch("prompt", nil)
  end
end
