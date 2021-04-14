#!/usr/bin/env ruby
require 'io/console'
require 'net/http'
require 'open-uri'
require 'resolv'
require 'socket'
require 'timeout'


def host(get_host) #get cname data and check response code for 404 and alert user
  Resolv::DNS.open do |dns|
    res = dns.getresources get_host, Resolv::DNS::Resource::IN::CNAME
    if res.empty?
      break
    end

    heroku_error = "there is no app configured at that hostname"
    amazonAWS_error = "NoSuchBucket"
    squarespace_error = "No Such Account"
    github_error = "There isn't a GitHub Pages site here"
    shopify_error = "Sorry, this shop is currently unavailable."
    tumblr_error = "There's nothing here."
    wpengine_error = "The site you were looking for couldn't be found."

    check_it = ""
    real_host = res.first.name.to_s
      check_real_host = "http://"+real_host
      check_it = Net::HTTP.get(URI.parse(check_real_host))
      if  (check_it.index("There is no app configured at that hostname"))
        puts "- Subdomain pointing to a non-existing Heroku app showing: " + heroku_error
      elsif (check_it.index("NoSuchBucket"))
        puts "- Subdomain pointing to an unclaimed AmazonAWS bucket showing: " + amazonAWS_error
      elsif (check_it.index("No Such Account"))
        puts "- Subdomain pointing to a non-existing SquareSpace account showing: " + squarespace_error
      elsif (check_it.index("You're Almost There"))
        puts "- Subdomain pointing to a non-existing SquareSpace account showing: " + squarespace_error
      elsif (check_it.index("There isn't a GitHub Pages site here"))
        puts "- Subdomain pointing to a non-existing Github subdomain indicating" + github_error
      elsif (check_it.index("Sorry, this shop is currently unavailable."))
        puts "- Subdomain pointing to a non-existing Shopify subdomain indicating" + shopify_error
      elsif (check_it.index("There's nothing here."))
        puts "- Subdomain pointing to a non-existing Tumblr subdomain indicating" + tumblr_error
      elsif  (check_it.index("The site you were looking for couldn't be found."))
        puts "- Subdomain pointing to a non-existing WPEngine subdomain indicating" + wpengine_error
      end
      #if (real_host = get_host)
      #else
        puts ("- Seems like " + get_host +  " is an alias for " + real_host)
      #end
  end
  return
end

def find_subs(targetURI)
      target = "http://"+targetURI
        begin
          #Timeout::timeout(600) {
            res = Net::HTTP.get_response(URI.parse(target))
            getCode = res.code
            ip_address = Resolv.getaddress targetURI
            if (getCode != "503")
              File.open(File.expand_path(File.dirname(__FILE__)) + "/output.txt", "a") do |file|
                file.puts targetURI
              end
              puts getCode + " " + targetURI + " ---> " + ip_address + " "
              if (ip_address == "127.0.0.1")
                puts "Sub domain is poiting to localhost --> Check for more details"
              else
              end
              host targetURI
            else
            end

            if getCode == "404"
              puts "----> Check for further information on where this is pointing to."
            end
          #}

        rescue Timeout::Error
        rescue Errno::EHOSTUNREACH
        rescue URI::InvalidURIError
        rescue SocketError
        rescue Errno::ECONNREFUSED
        rescue Resolv::ResolvError
        rescue Errno::ETIMEDOUT
        rescue Errno::ENETUNREACH
        end
#        recursiveBruteForce
end

def createURIThreaded(getURI)
  total_threads = 100 #safe value
  queue = Queue.new 
  File.open(File.expand_path(File.dirname(__FILE__)) + "/list.txt", "r") do |f|
    f.each_line do |line|
      targetURI = line.chomp + "." + getURI
      queue << targetURI
    end
    workers = total_threads.times.map do
      Thread.new do
        begin
          while targetURI = queue.pop(true)
            find_subs targetURI
          end
        rescue ThreadError
        end
      end
    end
    workers.map(&:join)
  end
end



File.open("output.txt", "w")
urlf = File.open(File.expand_path(File.dirname(__FILE__)) + "/url.txt")
getURI = urlf.read
urlf.close
createURIThreaded getURI