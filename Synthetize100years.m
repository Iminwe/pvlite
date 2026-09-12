for x=1:100
    SyntheticGeneration_Aguiar;
    G0a(x)=sum(sum(G0))/Stepph;; %Wh/m2
end
plot(G0a);

%Lenght of each month
MonthLength=[31,28,31,30,31,30,31,31,30,31,30,31];

G0a_initial=sum(Gdm0.*MonthLength)

G0a_average=mean(G0a)

Maximum=max(G0a)
sprintf('%.0f%%',100*(max(G0a)-G0a_average)/G0a_average)

Minimum=min(G0a)
sprintf('%.0f%%',100*(min(G0a)-G0a_average)/G0a_average)

plot(G0a)




