#!/usr/bin/env ruby
# coding: utf-8
#Description: 
#   sorting algorithms, inspired by Reddit
#     http://amix.dk/blog/post/19588

# hot topics
#
def post_hot_score(up, down, time)
  # 1249027200
  karma = up - down
  order = Math.log10([karma.abs, 1].max)
  sign = ( karma > 0 ? 1 : -1 )
  sign = 0  if karma == 0
  seconds = time.to_i - 1249027200

  (order + sign * seconds / 45000.0).round(7)
end

# controversial topics
#
def post_controversial_score(up, down, time)
  karma = up - down
  div = [karma.abs, 1].max
  n = up + down

  n / div
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
