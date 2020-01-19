   10 input"code";c
   15 input"data";d
   20 poke 829,int(c/256)
   25 poke 828,c-(int(c/256)*256)
   40 poke 831,int(d/256)
   45 poke 830,d-(int(d/256)*256)

