
require 'faraday'
require 'hashie'
require 'json'

def mashify(hash)
  Hashie::Mash.new(hash)
end

def color_puts(name, string)
  escape  = -> n { STDOUT.tty? ? "\033[#{n}m" : "" }
  colors = {
    red:     escape[31],
    green:   escape[32],
    yellow:  escape[33],
    blue:    escape[34],
    magenta: escape[35],
    cyan:    escape[36],
    reset:   escape[ 0]
  }
  puts colors[name] + string + colors[:reset]
end

def print_filenames(hashie)
  puts
  color_puts :blue, "********* filenames *********"
  hashie.each_with_index do |body, index|
    puts "#{index + 1}: " + body.files.first.first
  end
  color_puts :blue, "*****************************"
end

def print_file(file)
  puts
  color_puts :yellow, "******* file content ********"
  puts file.files.first.last.content
  color_puts :yellow, "*****************************"
end

def run
  @connection = Faraday.new(:url => 'https://api.github.com')

  puts "Who's gists do you want to see?"
  @username = gets.chomp
  @username = 'codezilla' if @username.empty?

  @request = @connection.get "/users/#{@username}/gists"
  bodies = JSON.parse(@request.body)

  @hashie_bodies = bodies.map { |body| mashify(body) }

  print_filenames(@hashie_bodies)
  while true
    puts 'What file would you like to view? (l)ist, (c)omment, (q)uit'
    input = gets.chomp

    if input.to_i == 0
      print_filenames(@hashie_bodies) if (input == 'l' || input == 'list')
      break if (input == 'q' || input == 'quit')
      comment_gist if (input == 'c' || input == 'comment')
    else
      index = input.to_i - 1
      file_url = get_gist_url(index)
      @file_request = Faraday.get file_url
      @file = mashify(JSON.parse(@file_request.body))
      print_file(@file)
    end
  end
end

def get_gist_url(index)
  @hashie_bodies[index].url
end

def comment_gist
  print_filenames(@hashie_bodies)
  puts 'What file would you like to comment? (l)ist, (q)uit'
  input = gets.chomp

  index = input.to_i - 1
  file_url = get_gist_url(index)

  auth
  @file_request = @connection.post file_url + '/comments', { :body => get_comment_body }
  puts @file_request.inspect
end

def get_comment_body
  puts "What is your comment?"
  gets.chomp
end

def auth
  unless @password
    puts "What is your Github password?"
    @password = gets.chomp
  end

  @connection.basic_auth(@username, @password)
end

run
