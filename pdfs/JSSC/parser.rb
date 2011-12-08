#! /usr/bin/ruby

require 'rubygems'
require 'hpricot'
require 'open-uri'

doc = Hpricot(open(ARGV[0]))

ttls = (doc/'td.blackbd').map{|x| x.inner_text}
bodies = (doc/'td.black').map{|x| x.inner_text}
links = (doc/'td.black').map{|x| (x/'a').map{|a| a['href']} }

#authors = bodies.map{|x| x.split(/\n/,2)[0]}
#info = bodies.map{|x| x.split(/\n/)[1].scan(/^([^,]+), +Vol\. *(\d+) *\((\d\d\d\d)\) *No\. *(\d+) *pp\. *(\d+-\d+)/)[0]}
#journals = info.map{|x| x.split(/,/,2)[0]}
#years = info.map{|x| x.scan(/\((\d\d\d\d)\)/)[0][0]}
#vols = info.map{|x| x.scan(/Vol\. (\d+)/)[0][0]}
#nums = info.map{|x| x.scan


data = bodies.map{|x| x.gsub(/\n/,'|')}.join("\n").scan(/^([^|]+)\|([^,]+),.*Vol\.\D*(\d+).*\((\d+)\).*No\.\D*(\d+).*pp\.\D*(\d+-\d+)/)

ttls.size.times do |i|
  title = ttls[i]
  abstract_link, pdf_link = *links[i]
  authors,journal,volume,year,number,pages = *data[i]
  first_page, last_page = * pages.split(/-+/)
  tag = [year,volume,first_page].join('_')
  pdf_file = "#{tag}_#{title}.pdf"
  unless File.file?(pdf_file)
    open(pdf_link,"rb") do |efile|
      open(pdf_file,"wb") do |out|
        out.write(efile.read)
        out.close
      end
    end
  end
  puts <<-NNN
@article{#{tag},
  author = "#{authors.split(/,/).join(' and ')}",
  title = "#{title}",
  journal = "#{journal}",
  year = "#{year}",
  volume = "#{volume}",
  pages = "#{pages}",
  number = "#{number}",
  url = "#{abstract_link}",
  memo = "PDF_LINK: #{pdf_link}",
  file = "#{pdf_file}:#{pdf_file}:PDF",
}

  NNN
end




