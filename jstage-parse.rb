#! /usr/bin/ruby -Ku

require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'tempfile'
require 'nkf'   # to convert UTF8

SERVER = "http://www.jstage.jst.go.jp"

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
KKK

ARGV.each do |uri|

  #file = Tempfile.new("journal-archive-work")
  file = open("resent.html","w+")
  open(uri){|u|
    file.write NKF.nkf("-w",u.read)
  }
  file.rewind

  html = Hpricot(file)

  file.close

  doc =Hpricot( (html/"body").inner_html )

  articles = (doc/:td).select{|x| x['bgcolor'] == "#FAF2FE"}
  links = articles.map{|x| (x/'a').map{|a| a['href']} }

  paper_list = articles.map{|a| (a/'table').select{|x|
    x['border'] == "0" && x['width'].nil? && x['height'].nil?
  }.first}
  bodies = paper_list.map{|x| x.inner_text.gsub(/\n/,'').strip.gsub(/\t+/,'|')}
  data = bodies.join("\n").scan(/^([^|]+)\s*\|\s*([^|]+)\s*\|\s*([^,]+),.*Vol\.\D*(\d+).*\((\d+)\).*No\.\D*(\d+).*pp\.\D*(\d+-\d+)/)

  dir = File.basename(Dir.pwd)

  data.size.times do |i|
    #$stderr.puts links[i]
    abstract_link, pdf_link = *links[i].map{|x| SERVER + x}
    ttl,authors,journal,volume,year,number,pages = *data[i].map{|x| x.strip}
    title = ttl.gsub(/:/,'：')
    next unless pages
    #authors = NKF.nkf("-Ws", authors)
    first_page, last_page = * pages.split(/-+/)
    if year == volume
      volume = number
      number = nil   # for JSCE
    end
    tag = [year,volume,first_page].join('_')
    pdf_file = "#{tag}_#{title}.pdf"
    unless File.file?(pdf_file)
      if $down
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
    #pdf_file = NKF.nkf("-Ws",pdf_file)
    #title = {#{NKF.nkf("-Ws",title)}},
    #journal = {#{NKF.nkf("-Ws",journal)}},
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



