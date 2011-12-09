#! /usr/bin/ruby -Ku

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'tempfile'
require 'nkf'   # to convert UTF8

SERVER = "http://www.jsce.or.jp"

def field(key, value)
  puts "  #{key} = {#{value}},\r"
end


if ARGV[0] == "-d"
  $down = true
  ARGV.shift
else
  $down = false
end

# ヘッダは最初に１回だけとする．
puts <<KKK
% This file was created with JabRef 2.7.2.\r
% Encoding: UTF8\r
\r
% created by #{$0} on #{Date.now}.\r
\r
KKK

ARGV.each do |uri|

  file = open("resent.html","w+")
  open(uri){|u|
    file.write NKF.nkf("-w",u.read)
  }
  file.rewind

  html = Hpricot(file)

  file.close

  doc =Hpricot( (html/"body").inner_html )
  jornal = (doc/:TITLE).first.inner_text.strip

  articles = (doc/:td).select{|x| (x/:a).size > 0}
  links = articles.map{|x| (x/'a').map{|a| a['href'].unshift(uri)} }

  data = articles.map{|a| (a/:td).map{|x| x.inner_text} }

  dir = File.basename(Dir.pwd)

  data.size.times do |i|
    abstract_link, pdf_link = *links[i].map{|x| SERVER + x}
    dummy,authors,ttl,volume,number,year,pages,img = *data[i].map{|x| x.strip}
    title = ttl.gsub(/:/,'：')
    next unless pages
    first_page, last_page = * pages.split(/-+/)
    if year == volume
      volume = number
      number = nil   # for JSCE
    end
    tag = [year,volume,first_page].join('_')
    pdf_file = "#{tag}_#{title}.pdf"
    unless File.file?(pdf_file)
      if $down && authors =~ /三木/
        $stderr.puts "Fetching #{pdf_file}"
        $stderr.puts "from: #{pdf_link}"
        open(pdf_link,"rb") do |efile|
          open(pdf_file,"wb") do |out|
            out.write(efile.read)
            out.close
          end
        end
      end
    end
    puts "@ARTICLE{#{tag},\r"
    field "author", authors.split(/,/).join(' and ')
    field "title", title
    field "journal", journal
    field "year", year
    field "volume", volume
    field "pages", pages
    field "number", number if number
    field "url", abstract_link
    field "memo", "PDF_LINK: #{pdf_link}"
    field "file", "#{pdf_file}:#{dir}\\\\#{pdf_file}:PDF"
    puts "}\r\n\r"
  end
end



