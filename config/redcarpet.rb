#!/usr/bin/env ruby
# coding: utf-8
#Description: Markdown renderer for Redcarpet
#
require 'pygments'

# a Markdown renderer with some limitations
class HTMLStripped < Redcarpet::Render::HTML
  include LoboHelpers

  def block_code(code, language)
    @language = Pygments::Lexer.find(language)
    @language = Pygments::Lexer.find(Pygments.lexer_name_for(code)) unless @language
    @language = Pygments::Lexer.find("text") unless @language
    @language.highlight(code, :options => {
      :encoding => 'utf-8'
#      :encoding => 'utf-8',
#      :linenos  => 'inline'
    })
  end

  def header(text, level)
    "<strong>#{'#'* level} #{text} #{'#' * level}</strong>"
  end

  def codespan(code)
    c = Category.with(:display_name, code) || Category.with(:name, code)
    c ? category_label(c) : ''
  end
end

MARKDOWN ||= Redcarpet::Markdown.new(
  HTMLStripped.new(
    :hard_wrap => true,
    :no_images => true,
    :filter_html => true,
    :no_styles => true,
  ),
  :fenced_code_blocks => true,
  :autolink => true,
  :superscript => true,
  :no_intra_emphasis => true,
  :lax_html_blocks => true,
  :tables => true,
  :strikethrough => true
)
