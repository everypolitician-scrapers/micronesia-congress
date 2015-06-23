#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

terms = { 
  19 => 'http://www.fsmcongress.fm/19th%20Congress/19members.html',
  18 => 'http://www.fsmcongress.fm/18th%20Congress/member.html',
  17 => 'http://www.fsmcongress.fm/17th%20Congress/members%20page.html',
}

def noko_for(url)
  Nokogiri::HTML(open(url).read) 
end

def scrape_list(term, url)
  noko = noko_for(url)
  noko.xpath('.//p[contains(., "Speaker")]/ancestor::table//img').each do |img|
    info = img.xpath('../following-sibling::p').map { |n| n && n.text.gsub(/[[:space:]]/, ' ').strip }.compact.reject(&:empty?)
    # Work around Vice Speaker Martin having an extra level of # nesting
    info = img.xpath('../../following-sibling::p').map { |n| n && n.text.strip }.compact if info.size.zero?
    info.first.sub! 'Senator ', ''

    photo = URI.join(url, URI.escape(img.attr('src'))).to_s
    # Ahem
    if photo == 'http://www.fsmcongress.fm/images/18th%20Congress/18c%20fsm%20foto/christianweb.2.jpg'
      info.unshift 'Peter M. Christian'
    end

    data = { 
      term: term,
      image: photo,
      party: 'none',
    }

    if info[1].include? 'State of'
      data[:name] = info[0]
      data[:role] = ''
      data[:area] = info[1].sub('State of ', '')
    else 
      data[:name] = info[1]
      data[:role] = info[0]
      data[:area] = "n/a"
    end
    puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

terms.each do |term, url|
  scrape_list(term, url)
end
