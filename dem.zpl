param fichier := "bin-packing-difficile-hard.bpa";

param capacite :=  read fichier as "1n" comment "#" skip 1 use 1;
param nbObjets :=  read fichier as "2n" comment "#" skip 1 use 1;
set Boites := { 0 to nbObjets-1} ;
set Objets := { 0 to nbObjets-1};
set tmp[<i> in Objets] := {read fichier as "<1n>" skip 2+i use 1};
param taille[<i> in Objets] := ord(tmp[i],1,1);
var y[Boites] binary;
var x[Objets*Boites] binary;

# obj : minimiser SOMME(y)
minimize valeur : sum<j> in Boites: y[j];
#contraintes
subto unObjParBoite : forall<i> in Objets : sum<j> in Boites: x[i,j] == 1;
subto boiteUtilisee : forall<i> in Boites : forall<j> in Objets :  x[i,j] <= y[j];
subto sommeTailleObj : forall<j> in Boites : sum<i> in Objets: x[i,j]*taille[i] <= capacite;
