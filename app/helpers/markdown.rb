#!/usr/bin/env ruby
# coding: utf-8
#Description: Markdown renderer for Redcarpet
#

# a Markdown renderer with some limitations
class HTMLStripped < Redcarpet::Render::HTML
  #def block_code(code, language)
    #Albino.safe_colorize(code, language)
  #end

  def header(text, level)
    "<strong>#{'#'* level} #{text} #{'#' * level}</strong>"
  end

  def codespan(code)
    c = Category.with(:display_name, code)
    c = Category.with(:name, code) unless c
    return "" unless c
    return "<a href='/l/#{c.name}' title='#{c.display_name}'>#{c.display_name}</a>"
  end
end

MARKDOWN ||= Redcarpet::Markdown.new(
  HTMLStripped.new(
    :hard_wrap => true,
    :no_images => true,
    :filter_html => true,
    :no_styles => true,
  )
)
