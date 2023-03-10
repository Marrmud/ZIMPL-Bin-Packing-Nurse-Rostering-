param fichier := "shift-scheduling.zplread" ;
do print fichier ;


####################
# Horizon = nb days

param horizon := read fichier as "2n" comment "#" match "^h";
do print "horizon : ", horizon, " jours" ;


############################################
# Sets of days, week-ends, services, staff :

set Days := {0..horizon-1} ;
# All instances start on a Monday
# planning horizon is always a whole number of weeks (h mod 7 = 0)
set WeekEnds := {1..horizon/7} ;
do print card(WeekEnds), " week-ends :" ;
do print WeekEnds ;

set Services := { read fichier as "<2s>" comment "#" match "^d" } ;
do print card(Services), " services" ; 

set Personnes := { read fichier as "<2s>" comment "#" match "^s" } ;
do print card(Personnes) , " personnels" ;


############
# Parameters

param duree[Services] := read fichier as "<2s> 3n" comment "#" match "^d";
# do forall <t> in Services  do print "durée ", t, " : ", duree[t] ;

param ForbiddenSeq[Services*Services] :=
	read fichier as "<2s,3s> 4n" comment "#"  match "c" default 0 ;


param MaxTotalMinutes[Personnes] :=
  read fichier as "<2s> 3n" comment "#" match "^s"  ;
param MinTotalMinutes[Personnes] :=
  read fichier as "<2s> 4n" comment "#" match "^s"  ;
param MaxConsecutiveShifts[Personnes] :=
  read fichier as "<2s> 5n" comment "#" match "^s"  ;
param MinConsecutiveShifts[Personnes] :=
  read fichier as "<2s> 6n" comment "#" match "^s"  ;
param MinConsecutiveDaysOff[Personnes] :=
  read fichier as "<2s> 7n" comment "#" match "^s"  ;
param MaxWeekends[Personnes] :=
  read fichier as "<2s> 8n" comment "#" match "^s"  ;

param MaxShift[Personnes*Services] :=
  read fichier as "<2s,3s> 4n" comment "#" match "^m" default 0 ;

param requirement[Days*Services] :=
  read fichier as "<2n,3s> 4n" comment "#" match "^r" ;

param belowCoverPen[Days*Services] :=
  read fichier as "<2n,3s> 5n" comment "#" match "^r" ;

param aboveCoverPen[Days*Services] :=
  read fichier as "<2n,3s> 6n" comment "#" match "^r" ;

param dayOff[Personnes*Days] :=
  read fichier as "<2s,3n> 4n" comment "#" match "^f" default 0 ;

# penalité si jour "pas off" = "on"
param prefOff[Personnes*Days*Services] :=
  read fichier as "<2s,3n,4s> 5n" comment "#" match "^n" default 0 ;

# penalité si jour "pas on" = "off"
param prefOn[Personnes*Days*Services] :=
  read fichier as "<2s,3n,4s> 5n" comment "#" match "^y" default 0 ;

# do print "Services" ;
# do forall <s> in Services do print s, duree[s] ;
# do forall <s1,s2> in Services*Services with ForbiddenSeq[s1,s2] == 1
#   do print s1, s2, ForbiddenSeq[s1,s2] ;
# do print "Staff" ; 
# do forall <p> in Personnes
#   do print p, MaxTotalMinutes[p], MinTotalMinutes[p],
#     MaxConsecutiveShifts[p], MinConsecutiveShifts[p],
#     MinConsecutiveDaysOff[p], MaxWeekends[p] ;
# do print "Days Off" ;
# do forall<p,d> in Personnes * Days with dayOff[p,d] == 1 do print p,d,dayOff[p,d] ;
# do print "Pref Shifts On" ;
# do forall<p,d,s> in Personnes * Days * Services
#   with prefOn[p,d,s] >= 1 do print p,d,s,prefOn[p,d,s] ;
# do print "Pref Shifts Off" ;
# do forall<p,d,s> in Personnes * Days * Services
#   with prefOff[p,d,s] >= 1 do print p,d,s,prefOff[p,d,s] ;
# do print "Cover" ;
# do forall<d,s> in Days * Services
#   do print d,s,requirement[d,s], belowCoverPen[d,s], aboveCoverPen[d,s] ;



###########
# Variables

var assigned[Personnes*Days*Services] binary;
var y[Days*Services] integer >=0;
var z[Days*Services] integer >=0;
var wpd[Personnes*Days] binary;

#minimize ecart: sum<d,s> in Days*Services: (y[d,s]+z[d,s]);
minimize ecart: (sum<d,s> in Days*Services: 
                          (aboveCoverPen[d,s]*y[d,s]+belowCoverPen[d,s]*z[d,s]))+
                (sum<p,d,s>in Personnes*Days*Services: 
                          (prefOff[p,d,s]*assigned[p,d,s]+prefOn[p,d,s]*(1-assigned[p,d,s]))) ;
#Ex1
subto nbPersDay: forall<d,s> in Days*Services: (sum<p> in Personnes: assigned[p,d,s]) - (y[d,s]-z[d,s]) == requirement[d,s];
#Ex2
subto nbPersService: forall<p,d> in Personnes*Days: (sum<s> in Services: assigned[p,d,s]) <= 1;
subto noWorkDayOff: forall<p,d> in Personnes*Days: (sum<s> in Services: assigned[p,d,s]) + dayOff[p,d] <= 1;
subto maxShits: forall<p,s> in Personnes*Services: (sum<d> in Days: assigned[p,d,s]) <= MaxShift[p,s];
subto  maxServiceTemps: forall<p> in Personnes: (sum<d,s> in Days*Services: assigned[p,d,s]*duree[s])<=MaxTotalMinutes[p];
subto  minServiceTemps: forall<p> in Personnes: (sum<d,s> in Days*Services: assigned[p,d,s]*duree[s])>=MinTotalMinutes[p];
#Ex3
subto persWorksDayD: forall<p,d> in Personnes*Days: (sum<s> in Services: assigned[p,d,s]) == wpd[p,d]; #exercice 4 mais redef pour MaxConsShift

subto maxConsecShifts: forall<p> in Personnes: forall<j> in {0..horizon-1-MaxConsecutiveShifts[p]}:
                                        (sum<d> in {j to (j+MaxConsecutiveShifts[p])}: wpd[p,d]) <= MaxConsecutiveShifts[p];
subto forbiddenSeqs: forall<p,d,s1,s2> in Personnes*Days*Services*Services with(d<horizon-1): (assigned[p,d,s1] + ForbiddenSeq[s1,s2] + assigned[p,d+1,s2]) <= 2;
#Ex4
subto cMinConsecutiveDaysOff: forall<p> in Personnes: forall <k> in {2..MinConsecutiveDaysOff[p]}: forall <j> in {0..horizon-1-k}:
                                wpd[p,j]+wpd[p,(j+k)]-1<= (sum<n> in {j+1..j+(k-1)}: wpd[p,n]);
subto cMinConsecutiveShifts: forall<p> in Personnes: forall<k> in {2..MinConsecutiveShifts[p]}: forall<j> in {0..horizon-k-1}:
                                (1-wpd[p,j])+(1-wpd[p,k+j])-1 <= (sum<n> in {j+1..k+j-1}: (1-wpd[p,n]));
# subto cMinConsecutiveShifts: forall<p> in Personnes : forall <k> in {2..MinConsecutiveShifts[p]} : forall <j> in {0..horizon-1-k}:
#                                wpd[p,j]+wpd[p,(j+k)] >= (sum<n> in {j+1..j+(k-1)}: sum<s> in Services: (assigned[p,n,s]) - (k-2));