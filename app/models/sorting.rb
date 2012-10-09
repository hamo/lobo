#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#   sorting algorithms, inspired by Reddit
#     http://amix.dk/blog/post/19588

# hot topics
#   original reddit sorting   log10(z) + y * t /12.5h
#def post_hot_score(up, down, time)
  ## 1249027200
  #karma = up - down
  #order = Math.log10([karma.abs, 1].max)
  #sign = ( karma > 0 ? 1 : -1 )
  #sign = 0  if karma == 0
  #seconds = time.to_i - 1249027200

  #(order + sign * seconds / 45000.0).round(7)
#end

# new hot topic sorting
#   the idea is that a yesterday's post with 10 upvotes should be better than a
#   today's post with 3 votes, nature logrithm is used insead of base 10
#
#     log(10) - log(3) > 24h/b =>  b = 20h
#
#   the equation is thus like
#
#     log(z) + y * t / 20h
#   
def post_hot_score(up, down, time)
  # 1249027200
  karma = up - down
  order = Math.log([karma.abs, 1].max)
  sign = ( karma > 0 ? 1 : -1 )
  sign = 0  if karma == 0
  seconds = time.to_i - 1249027200

  (order + sign * seconds / 72000.0).round(7)
end

# controversial topics
#
def post_controversial_score(up, down, time)
  karma = up - down
  div = [karma.abs, 1].max
  n = up + down

  (n.to_f / div).round(7)
end

# hot comments
#
def comment_hot_score(up, down, time)
  n = (up + down)

  return 0.0  if n.zero? 

  # http://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval#Wilson_score_interval
  #
  n = n.to_f
  frac = up / n
  # 1.0 = 85% 1.6 = 95%
  z = 1.0 

  Math.sqrt( frac + z*z/(2*n) - z*z*( (frac*(1-frac) + z*z/(4*n)) /n ) ) / ( 1 + z*z / n )

end
