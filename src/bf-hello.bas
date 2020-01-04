   10 c=6400
   15 d=7000
   20 poke 829,int(c/256)
   25 poke 828,c-(int(c/256)*256)
   40 poke 831,int(d/256)
   45 poke 830,d-(int(d/256)*256)
   50 read bf$:if bf$="end"then pokec,42:end
   55 for i=1tolen(bf$)
   60 t$=mid$(bf$,i,1)
   65 poke c,asc(t$)
   70 c=c+1
   75 next i
   80 goto 50
  100 data "++++++++"
  101 data "[>++++"
  102 data "[>++>+++>+++>+<<<<-]"
  103 data ">+>+>->>+"
  104 data "[<]<-]"
  105 data ">>.>---."
  106 data "+++++++..+++"
  107 data ".>>.<-.<."
  108 data "+++.------."
  109 data "--------.>>"
  110 data "+.>++."
 10000 data "end"

