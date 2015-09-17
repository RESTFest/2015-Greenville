require 'pry'
require_relative 'client.rb'
require 'active_support'
require 'active_support/core_ext'

class CommandLine
  attr_reader :collection

  def run
    @collection ||= client.get("/")

    puts "What do you want to do?"
    puts "  - Refresh Items (refresh)"
    puts "  - Items (items)"
    puts "  - Queries (queries)"
    puts "  - Template '#{collection.template.prompt}' (template)" if collection.template
    puts "  - Delete (delete)"
    puts "  - Edit (edit)"
    puts "  - Exit (exit)"

    choice = gets.chomp
    puts

    case choice
    when "refresh"
      refresh
    when "items"
      print_items(collection.items)
    when "queries"
      queries
    when "template"
      template
    when "delete"
      delete
    when "edit"
      edit
    when "exit"
      return
    end

    run
  end

  def refresh
    @collection = client.get(collection.href)
  end

  def queries
    queries = collection.queries.map do |query|
      "#{query.prompt} (#{query.rel})"
    end
    puts queries

    puts "Choose a query"
    query = gets.chomp

    search_query = collection.query(query)

    unless search_query
      puts "Query not found"
      return
    end

    puts

    if search_query.data.all? { |data| data.value.empty? }
      edit = "yes"
    else
      search_query.data.each do |data|
        puts "#{data.prompt}: #{data.value}"
      end

      puts "Edit? (yes/no)"
      edit = gets.chomp
      puts
    end

    case edit
    when "yes"
      search_query.data.each do |data|
        if data.value.present?
          puts "#{data.prompt} (#{data.value}):"
        else
          puts "#{data.prompt}:"
        end
        search_query.set(data, gets.chomp)
      end
      puts
    when "no"
      search_query.data.each do |data|
        search_query.set(data, data.value)
      end
    end

    collection = client.get(search_query.to_url)

    print_items(collection.items)
  end

  def template
    template = collection.template
    puts template.prompt
    template.data.each do |data|
      if data.value.present?
        puts "#{data.prompt} (#{data.value}):"
      else
        puts "#{data.prompt}:"
      end
      template.set(data, gets.chomp)
    end
    puts

    @collection = client.add_template(collection, template)
  end

  def delete
    item = choose_item
    @collection = client.delete(item)
  end

  def edit
    item = choose_item

    @collection = client.get(item.href)

    item = collection.items.first
    template = collection.template

    item.data.each do |data|
      next unless template.data.any? { |td| td.name == data.name }
      if data.value.present?
        puts "#{data.prompt} (#{data.value}):"
      else
        puts "#{data.prompt}:"
      end
      template.set(data, gets.chomp)
    end

    @collection = client.update(item, template)
  end

  private

  def client
    @client ||= Client.new("http://hyper-hackery.herokuapp.com/")
  end

  def choose_item
    print_items(collection.items, true)

    puts "Choose an item"
    item_number = gets.chomp.to_i

    collection.items[item_number]
  end

  def print_items(items, include_numbers = false)
    puts "Returned items"
    items.each_with_index do |item, index|
      value = item.attribute("completed").value
      finished = value == "true" || value == true ? "(X)" : "( )"
      number = " (#{index})" if include_numbers
      puts "  - #{finished}#{number} #{item.attribute("title").value}"
    end
    puts
  end
end


CommandLine.new.run
