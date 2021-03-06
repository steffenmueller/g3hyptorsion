AttachSpec("spec");
import "heights.m": normalize;
import "transformations.m": KummerTransformation;

// counts the number of generators of the rational 2-torsion subgroup (Section 5.6)
function counttwotorsiongens(J)
    C := Curve(J);
    f,h := HyperellipticPolynomials(C);
    assert h eq 0;
	fact := Factorization(f); // f is now of degree 8.
	fact1 := [ pair[1] : pair in fact | Degree(pair[1]) eq 1 ];
    fact2 := [ pair[1] : pair in fact | Degree(pair[1]) eq 2 ];
    fact3 := [ pair[1] : pair in fact | Degree(pair[1]) eq 3 ];
    fact4 := [ pair[1] : pair in fact | Degree(pair[1]) eq 4 ];	
	gensct := 0;
	gensct +:= (#fact1 ge 2) select #fact1 - 1 else 0;
	gensct +:= #fact2;
	gensct +:= (#fact1 ne 0) select #fact3  else 0;
	gensct +:= #fact4;
    if #fact1 + 2*#fact2 + ((#fact1 ge 1) select 3*#fact3 else 0) 
                + 4*#fact4 eq Degree(f) then gensct -:= 1; end if;
	return gensct;
end function;

// Explicitly computes the rational 2-torsion subgroup for 
intrinsic myTwoTorsionSubgroup(J::JacHyp) -> GrpAb, Map
{The rational 2-torsion subgroup of J for curves of genus 2 in simplified model.}
    if assigned J`TwoTorsion then 
        return J`TwoTorsion[1], J`TwoTorsion[2];
    end if;
    C := Curve(J);
    require Degree(C) mod 2 eq 1 or Genus(C) le 4:
        "TwoTorsionSubgroup is currently only implemented for Jacobians",
        "of odd degree curves or genus 2, 3 curves.";
    if Degree(C) mod 2 eq 1 then
        f,h := HyperellipticPolynomials(C);
        require h cmpeq 0:
            "TwoTorsionSubgroup requires a curve in the form y^2 = f(x)";
        fact := Factorization(f);
        gens := Prune([J![ g[1],0] : g in fact ]); 
        G<[P]> := AbelianGroup([2 : i in [1..#gens]]);
        L := [ J!0 ];
        for g in gens do L cat:= [ g + pt : pt in L ]; end for;
        iso := map< G -> J | g :-> &+[J | s[i]*gens[i] : i in [1..#s]]
                                                    where s := Eltseq(g) >;
        J`TwoTorsion := <G, iso, L>;
        return G,iso;
    end if;
    
    // this part is added for genus 3, degree 8 curves. (Section 5.8)
    if Genus(C) eq 3 then
        f,h := HyperellipticPolynomials(C);
	  	require h cmpeq 0:
	  	  "TwoTorsionSubgroup requires a curve in the form y^2 = f(x)";
	  	fact := Factorization(f); // f is now of degree 8.
	  	fact1 := [ pair[1] : pair in fact | Degree(pair[1]) eq 1 ];
        fact2 := [ pair[1] : pair in fact | Degree(pair[1]) eq 2 ];
        fact3 := [ pair[1] : pair in fact | Degree(pair[1]) eq 3 ];
        fact4 := [ pair[1] : pair in fact | Degree(pair[1]) eq 4 ];
        if #fact1 ge 2 then
            gens := [ J ! [ pol1*fact1[i], 0 ] : i in [2..#fact1] ]
                where pol1 := fact1[1];
        else
            gens := [];
            end if;
            gens cat:= [ J ! [ pol, 0 ] : pol in fact2 ]; 
        if #fact1 ge 1 then
            gens cat:= [ J ! [pol*fact1[1], 0] : pol in fact3];
        end if;
        gens cat:= [ J ! [ pol, 0 ] : pol in fact4 ];
        if #fact1 + 2*#fact2 + ((#fact1 ge 1) select 3*#fact3 else 0) 
                + 4*#fact4 eq Degree(f) then 
            Prune(~gens); 
        end if;
        L := [ J!0 ];
        for g in gens do L cat:= [ g + pt : pt in L ]; end for;
            G<[P]> := AbelianGroup([ 2 : i in [1..#gens] ]);
            iso := map< G -> J | g :-> &+[J | s[i]*gens[i] : i in [1..#s]]
                                     where s := Eltseq(g) >;
            J`TwoTorsion := <G, iso, L>;
        return G, iso;    
    end if;

    assert Genus(C) eq 2;
    f, h := HyperellipticPolynomials(C);
    require h eq 0:
       "TwoTorsionSubgroup requires a curve in the form y^2 = f(x).";
    fact := Factorization(f);
    // look for factors of degree 2
    fact1 := [ pair[1] : pair in fact | Degree(pair[1]) eq 1 ];
    fact2 := [ pair[1] : pair in fact | Degree(pair[1]) eq 2 ];
    if Degree(f) eq 5 then
        gens := [ J ! [pol, 0] : pol in fact1 ];
    elif #fact1 ge 2 then
        gens := [ J ! [ pol1*fact1[i], 0 ] : i in [2..#fact1] ]
              where pol1 := fact1[1];
    else
        gens := [];
    end if;
    gens cat:= [ J ! [ pol, 0 ] : pol in fact2 ];
    if #fact1 + 2*#fact2 eq Degree(f) then Prune(~gens); end if;
    L := [ J!0 ];
    for g in gens do L cat:= [ g + pt : pt in L ]; end for;
    G<[P]> := AbelianGroup([ 2 : i in [1..#gens] ]);
    iso := map< G -> J | g :-> &+[J | s[i]*gens[i] : i in [1..#s]]
                               where s := Eltseq(g) >;
    J`TwoTorsion := <G, iso, L>;
    return G, iso;
end intrinsic;

// The algorithm used in this function can be found on
// Canonical heights on the Jacobians ofcurves of genus 2 and the infinite descent
// by E.V. Flynn, N.P. Smart, Acta Arithmetica 79, part 4, 333-352.
/* ~ This function has been replaced by functionality in KummerArithmetic.m
function myHasPointOrder(C, P, n, B)
    // Tests whether P::KummerPt on C::CrvHyp (on K over the rationals) is a torsion
    // point of order n. B is a bound for the non-logarithmic naive height
    // of a torsion point.
    check := func< pt | Abs(pt[1]) gt B or Abs(pt[2]) gt B
                         or Abs(pt[3]) gt B or Abs(pt[4]) gt B 
                         or Abs(pt[5]) gt B or Abs(pt[6]) gt B
                         or Abs(pt[7]) gt B>;
    m := n;
    Px := KummerOrigin(C); Py := P; Pz := P;
    while true do
      if IsOdd(m) then
        Px := PseudoAdd(C, Px, Pz, Py);
        if check(Px) then return false; end if;
      else
        Py := PseudoAdd(C, Py, Pz, Px);
        if check(Py) then return false; end if;
      end if;
      m div:= 2;
      if m eq 0 then return Px eq KummerOrigin(C); end if;
      Pz := Double(C, Pz);
      if check(Pz) then return false; end if;
    end while;
end function;*/

function normalizetoaffine(seq)
	i := 1;
	while i ne 9 and not IsUnit(seq[i]) do i +:= 1; end while;
	newseq := [a / seq[i] : a in seq];
	return newseq;
end function;

// This function decides whether a reduced point P on J(F_p) lifts to J(Q) or not. (Algorithm 4.2)
function myLiftTorsionPoint(P, C, b, B: transmat := [1,0,0,1])
// (P::JacHypPt, C::CrvHyp, b::RngIntElt, B::FldReElt, transmat::RngMatElt) -> BoolElt, JacHypPt
// C = genus 3 curve over the rationals,
// P = point on Jacobian over F_p,
// b = bound for p-adic approximation precision. (Section 4.4)
// B = height bound for torsion points (Theorem 3.15)
// transmat: Transformation matrix for a local change of coordinates (Section 5.5)
    f := HyperellipticPolynomials(C);
    p := #CoefficientRing(Parent(P));   // p s.t. P in J(F_p)
    J := Jacobian(C);
    Jp := Parent(P);
    Dp := Curve(Jp);
    Cp := Curve(BaseChange(Jacobian(C), GF(p)));
    kumtransinv := KummerTransformation(Dp, Cp, ChangeUniverse(transmat, GF(p)));
    prec := 1;
    n := Order(P);
    if n eq 2 then // we compute the 2-torsion subgroup directly.
        tt := myTwoTorsionSubgroup(J);
        tt := J`TwoTorsion[3];
        K := KummerVarietyG3(C);
        Kp := KummerVarietyG3(Dp);
        PKp := ToKummerVariety(P);
        for i := 2 to #tt do
            ttes := Eltseq(ToKummerVariety(tt[i]));
            integral_P := normalize(ttes);
            if Kp!ChangeUniverse(integral_P, GF(p)) eq Kp!Eltseq(PKp) then return true, tt[i]; end if;
        end for;
        return false, _;
    end if;
    // Decide on the integer m used as [[m]]R in Step 3.3. doubleflag decides whether [[m]]R can be
    // achieved through repeated doubling (Section 4.7)
    if n mod 2 eq 0 then
        m := 1 - n; // smallest m congruent to 1 mod n
        doubleflag := false;
    else
    a := EulerPhi(n);
        for d in Divisors(a) do
            if 2^d mod n eq 1 then
                order := d;
                break;
            end if;
        end for;
        m := 2^order;
        if (m - 1) mod p eq 0 then
            doubleflag := false;
            m := 1 - n;
        else
            doubleflag := true;
        end if;
    end if;
    K := KummerVarietyG3(C);
    // first lift
    F := GF(p);
    Kp := KummerVarietyG3(Curve(BaseChange(J, F)));
    PK:= Eltseq(kumtransinv(ToKummerVariety(P)));
    // applies LLL-reduction to find a short vector. 
    L := Lattice(8, ChangeUniverse(Eltseq(PK), Integers())
                   cat [p,0,0,0,0,0,0,0, 0,p,0,0,0,0,0,0, 0,0,p,0,0,0,0,0, 0,0,0,p,0,0,0,0,
                        0,0,0,0,p,0,0,0, 0,0,0,0,0,p,0,0, 0,0,0,0,0,0,p,0, 0,0,0,0,0,0,0,p]);
    app := Eltseq(Basis(L)[1]);
    while prec lt b do // This iterates Step 3.
        // next lift
        newprec := Min(2*prec,b);
        oldF := F;
        F := Integers(p^newprec);
        // Onew := O(F!p^newprec);
        OldKp := Kp;
        Kp := KummerVarietyG3(C: Ambient := ProjectiveSpace(F, 7));
        // lift point to P^7 with new precision
        s := ChangeUniverse(Eltseq(PK), Integers()); 
        // uses a step in multivariate Newton Iteration to ensure that s
        // lifts to a point on the Kummer with sufficient precision.
        P_int := ChangeUniverse(Eltseq(s), Integers());
        kv := -Vector(oldF, [oldF| ExactQuotient(Evaluate(eqn, P_int), p^prec) : eqn in Equations(K)]); 
        jac := JacobianMatrix(DefiningEquations(OldKp));
        dkv := Matrix(oldF, [[Evaluate(jac[i,j], Eltseq(PK)) : j in [1..NumberOfColumns(jac)]]
                          : i in [1..NumberOfRows(jac)]]);
        if Rank(dkv) lt 4 then
            print "Working on point:", s;
            error "Singularity detected!";
        end if;
        sol, ker := Solution(Transpose(dkv), kv);
        sol := ChangeRing(sol, Integers());
        s1 := s;
        s1 := Vector(s) + p^prec * sol; // this is the actual Newton iteration step.
        if not doubleflag then	
            s2 := Kp!Eltseq(Multiple(C, m, Kp!Eltseq(s1) : Ambient := ProjectiveSpace(F, 7)));
        else
            s2 := s1;
            for i := 1 to order do
                s2 := Double(C, Kp!Eltseq(s2) : Ambient := ProjectiveSpace(F, 7));
            end for;
        end if;
        s1 := ChangeRing(s1, F);	
        s1 := normalizetoaffine(Eltseq(s1));		
        s2 := normalizetoaffine(Eltseq(s2));
        i := 1;
        while i ne 9 and Integers() ! (s1[i] - s2[i]) mod p^prec eq 0 do i +:= 1; end while;
        if i ne 9 then print p, prec, s1, s2; end if;
        error if i ne 9,
	        "LiftTorsionPoint: Precision loss!!";
        PK := [F | (m*(Integers()!s1[i]) - Integers()!s2[i])/(m-1) : i in [1..8] ];  
        // compute approximation
        q := p^newprec;
        // we already check whether we have found a lift with each iteration (Remark 4.17)
        L := Lattice(8, ChangeUniverse(PK, Integers())
                       cat [q,0,0,0,0,0,0,0, 0,q,0,0,0,0,0,0, 0,0,q,0,0,0,0,0, 0,0,0,q,0,0,0,0,
                            0,0,0,0,q,0,0,0, 0,0,0,0,0,q,0,0, 0,0,0,0,0,0,q,0, 0,0,0,0,0,0,0,q]);
        app1 := Eltseq(Basis(L)[1]);
        if app eq app1 and IsPointOnKummer(C, app1) then
            PQ := K!app1;
            if Multiple(C, n, PQ) eq KummerOrigin(C) then	
                if Degree(f) eq 7 then
          	        PJ := LiftToJacobian(C, PQ);
          	        if IsEmpty(PJ) then
	          	        return false, _;
                    else
                        return true, PJ[1];
                    end if;
                else // for the time being, explicit generators are only computed for odd degree.
                    return doesLiftToJacobian(C, PQ), _; 
                end if;   
            end if;
        end if;
        prec := newprec; app := app1; // prepare for new iteration.
    end while;
    // Step 5-7
	// now prec = b. Check if found
    if not IsPointOnKummer(C, app) then 
        return false, _; 
    end if;
	PQ := K!app;
    if Multiple(C, n, PQ) ne KummerOrigin(C) then 
        return false, _; 
    end if;
    // for the time being, explicit generators are only computed for odd degree.
    if Degree(f) eq 7 then
        PJ := Points(J, PQ);
        if IsEmpty(PJ) then 
            return false, _; 
        else 
            return true, PJ[1]; 
        end if;
    else
        return doesLiftToJacobian(C, PQ), _;
    end if;
end function;

/* The code of this function compares well to Stoll's paper on genus 2
curves [1], section 11, the second algorithm (bottom of pg. 200). 
This function translates almost immediately to the genus 3 case, but
there are some issues for curves where Jacobian arithmetic is not implemented.*/

// Algorithm 4.22.
intrinsic myTorsionSubgroup(J::JacHyp)
    -> GrpAb, Map
{Finds the rational torsion subgroup of J. The curve of J must have genus 2
 and be defined over the rationals and have form  y^2 = f(x)  with integral 
 coefficients. Second value gives the map from the group into J. }
    C := Curve(J);
    tstart := Cputime();
    tlift := 0.0;
    require Genus(C) eq 3 and CoefficientRing(C) cmpeq Rationals():
            "This function is designed",
            "for Jacobians of genus 3 curves over the rationals.";
    f, h := HyperellipticPolynomials(C);
    require h eq 0 and &and[ Denominator(c) eq 1 : c in Coefficients(f)]:
            "TorsionSubgroup needs a curve of the form  y^2 = f(x),",
            "where f has integral coefficients.";
    vprint JacHypTorsion: "TorsionSubgroup of J = \n",J;
        // flaglt decided whether one needs a transfomation of reduced curves to allow computation
        // on reduced Jacobians.
    flaglt := not HasOddDegreeModel(C) and #PointsAtInfinity(C) eq 0;
    
    // We prefer to compute using an odd degree model if we can find one.	
    if Degree(f) eq 8 and HasOddDegreeModel(C) then
        _, D, trans := HasOddDegreeModel(C);
        DS, DStrans := SimplifiedModel(D);
        DI, DItrans := IntegralModel(DS);
        D := DI; trans := trans * DStrans * DItrans;
        JD := Jacobian(D);
        vprint JacHypTorsion: "Considering isomorphic odd degree model...";
        G, iso := myTorsionSubgroup(JD);
        /*transinv := Inverse(trans);
        Jtransinv := map<JD -> J | P :-> Evaluate(transinv, P)>;*/
        return G; //, iso*Jtransinv;
    end if;
    bound := HeightConstantG3(J);
    // This bounds the logarithmic naive height of the torsion points
    vprint JacHypTorsion: " Height Constant =",bound;
    Bound := Exp(bound);           // non-log height bound
    // changed in order to be safe for now.
    bound1 := Log(2048.0) + 2*bound; // logarithmic bound for p-adic precision (section 4.4).
    // Get a bound for the order of the torsion subgroup
    //  (by looking at the reduction at a few good primes).
    tb := TorsionBound(J, 10);
    tb1 := J`TorsionBound[3];
    fact := Factorization(tb);
    vprintf JacHypTorsion: " Torsion Bound = %o, factored: %o\n",tb,fact;
    // Initialize data for group.
    ed := [];      // elementary divisors
    gL := [ J | ]; // generators
    ttc := counttwotorsiongens(J); // if no unique representation exists, we compute implicitly now.
    // compute q-part of torsion subgroup. (Algorithm 4.20)    
    for pair in fact do
        q := pair[1];
        vprintf JacHypTorsion: "  Determining %o-part...\n",q;
        // Find p such that J(F_p) has minimal p-valuation and p ne q.
        if flaglt then
            minval := 1000;
            for t in tb1 do // we also require that J(F_p) contains a point (Section 5.5)
                if Valuation(t[2],q) lt minval and 
                                    #Points(Curve(BaseExtend(J, GF(t[1])))) ne 0 and t[1] ne q then
                    p := t[1];
                    e := Valuation(t[2], q);
                    minval := Valuation(t[2],q);
                end if;
            end for;
        else
      	    e, pos := Min([ Valuation(t[2],q) + (t[1] eq q select 1000 else 0) : t in tb1]);
            p := tb1[pos][1];
        end if;
        vprintf JacHypTorsion: "   Using prime %o; %o-torsion has order %o^%o\n",p,q,q,e;
        pbound := Ceiling(bound1/Log(p));
        vprintf JacHypTorsion: "   Approximation up to O(%o^%o)\n",p,pbound;
        // Compute q-subgroup of J(F_p)		
        Jp := BaseExtend(J, GF(p));
        if flaglt then
            Cp := Curve(Jp);
            if #PointsAtInfinity(Cp) ge 1 then
                mat := [1,0,0,1];
                Dp := Cp;
                JDp := Jacobian(Dp);
            else // Map a point to infinity (Lemma 2.44)
                pts := Points(Cp);
                x1 := Eltseq(pts[1])[1];
                mat := [GF(p) |0,1,1,-x1];
                Dp, _ := Transformation(Cp, mat);
                JDp := Jacobian(Dp);
            end if;
        end if;

        if GetVerbose("JacHypTorsion") gt 0 then
            Kp := BaseExtend(KummerVarietyG3(C), ProjectiveSpace(GF(p), 7));
        end if;
        if flaglt then
            Gp, mp := Sylow(JDp, q);
        else
            Gp, mp := Sylow(Jp, q);
        end if;
        inv := Invariants(Gp);
        vprintf JacHypTorsion: "   Structure of %o-subgroup: %o\n",q,inv;
        // Determine subgroup of points that lift to J(Q)
        Tcurr := sub<Gp |>;
        Tgens := [Gp | ];
        if Degree(f) eq 7 then
            Tgimages := [J | ];
        end if;
        Gcurr, qmap := quo<Gp | Tcurr>;
        S0 := { Gcurr | 0 };
        S1 := Set(Gcurr) diff S0;
        while not IsEmpty(S1) do    // run through reduced points on J(F_p)
            vprint JacHypTorsion:
               "    Current subgroup has invariants", Invariants(Tcurr);
            vprint JacHypTorsion:
               "     There are at most",#S1 div (q-1),"elements to be tested.";
            // Choose some element in S1
            g := Rep(S1);
            // Make it primitive
            g := Gcurr![ s div gcd : s in gs ]
               where gcd := GCD(gs)
               where gs := Eltseq(g);
            // Find smallest j such that q^j*g lifts
            j := 0; gg := g;
            while gg ne Gcurr!0 do
                gl := gg @@ qmap; // Some preimage in Gp
                pt := mp(gl);     // and the corresponding point on J(F_p)
                // here, we stop trying if gg in J[2] and compute J[2] separately.
                if flaglt and Order(pt) eq 2 then
                    flag := true;
                    vprint JacHypTorsion: "     2-torsion determined without lifting";
                else
                    vprint JacHypTorsion: "     Trying to lift point",pt,"...";
                    vprintf JacHypTorsion, 2:
                        "     Image on Kummer surface = %o\n", ToKummerVariety(pt);
                end if;
                tt := Cputime();
                if flaglt and Order(pt) ne 2 then
                    flag := myLiftTorsionPoint(pt, C, pbound, Bound: transmat := mat);
                elif not flaglt then
                    flag, lift := myLiftTorsionPoint(pt, C, pbound, Bound);
                end if;          
                tlift +:= Cputime(tt);
                if flag and Degree(f) eq 7 then 
                    vprintf JacHypTorsion: "     Point lifts";
                    vprintf JacHypTorsion, 2: " to %o", lift;
                    vprintf JacHypTorsion: "\n";
                    break;
                elif flag and not (Order(pt) eq 2 and flaglt) then
                    vprint JacHypTorsion: "     Point lifts (non-explicitly)";
                    break;
                elif not (Order(pt) eq 2 and flaglt) then
                    vprint JacHypTorsion: "     Point does not lift";
                end if;
                j +:= 1;
                gg := q*gg;
            end while; // gg ne Gcurr!0
            // Here, gg = q^j*g, and gl is a preimage of gg in Gp
            if gg ne Gcurr!0 then
                // Can enlarge current subgroup
                Append(~Tgens, gl);
                if Degree(f) eq 7 then
                    Append(~Tgimages, lift);
                end if;
                Tcurr := sub<Gp | Tcurr, gl>;
                Gcurr, qmap1 := quo<Gcurr | gg>;
                qmap := qmap*qmap1;
                // Note new elements we know don't lift
                S0 := qmap1(S0) join { k*g1 : k in [1..q^j-1] } where g1 := qmap1(g);
                S1 := Set(Gcurr) diff S0;
                if q eq 2 then // we found precisely one 2-torsion point.
                    ttc -:= 1;
                end if;
            else // gg eq Gcurr!0
                // Note new elements we know don't lift
                Snew := { k*g : k in [1..q^j-1] };
                S0 join:= Snew;
                S1 diff:= Snew;
            end if; // gg ne Gcurr!0
        end while; // not IsEmpty(S1)
        // Now, Tcurr is the subgroup of Gp of points that lift to J(Q).
        // Find generators in J(Q).
        invs := Invariants(Tcurr);
        // we consider the 2-torsion points that are generators here.
        if flaglt and q eq 2 then
            invs := invs cat [2 : i in [1..ttc]];
        end if;
        vprintf JacHypTorsion:
            "   The %o-part of the torsion subgroup has invariants %o\n",
            q, invs;
        if Degree(f) eq 7 then
            if not IsEmpty(Tgens) then
            // This `if' is necessary since Magma 2.4 barfs on
            //  hom< G -> G | [G|] > where G := FreeAbelianGroup(0)
            vprintf JacHypTorsion:
                "  Determining generators for the %o-part...\n",q;
            qqmap := hom< FreeAbelianGroup(#Tgens) -> Tcurr | Tgens >;
            Lp1 := [ &+[ s[j]*Tgimages[j] : j in [1..#s] ]
                where s :=  Eltseq(Tcurr.i @@ qqmap)
                : i in [1..#invs] ];
            if GetVerbose("JacHypTorsion") ge 2 then
                print "   Generators with their orders:";
                for i := 1 to #invs do
                    print "    ", Lp1[i], ",  of order", invs[i];
                end for;
            end if; // GetVerbose("JacHypTorsion") ge 2
	 
            // Now put q-part together with what we've got so far.
            d := #invs-#ed;
            vprintf JacHypTorsion:
                "  Combining %o-part with what we've already got...\n",q;
            if d gt 0 then
                ed := invs[[1..d]] cat [ Lcm(ed[i], invs[i+d]) : i in [1..#ed] ];
                gL := Lp1[[1..d]] cat [ gL[i] + Lp1[i+d] : i in [1..#gL] ];
            else
                ed := ed[[1..-d]] cat [ Lcm(ed[i-d], invs[i]) : i in [1..#invs] ];
                gL := gL[[1..-d]] cat [ gL[i-d] + Lp1[i] : i in [1..#Lp1] ];
                end if;
            end if; // not IsEmpty(Tgens)
            vprint JacHypTorsion: "  Current invariants:",ed;
        else // Degree(f) ne 7: We treat this case implicitly for the time being.
            if invs ne [] then
                d := #invs - #ed;
                if d gt 0 then
                    ed := invs[[1..d]] cat [ Lcm(ed[i], invs[i+d]) : i in [1..#ed] ];
                else
                    ed := ed[[1..-d]] cat [ Lcm(ed[i-d], invs[i]) : i in [1..#invs] ];
                end if;
            end if;
        end if;											
    end for; // pair in fact
    vprintf JacHypTorsion: "\n";
    // Construct the abstract group
    G<[P]> := AbelianGroup(ed);   
    vprint JacHypTorsion: " Torsion subgroup has structure", ed;
    if Degree(f) eq 7 then 
        if GetVerbose("JacHypTorsion") ge 2 and not IsEmpty(ed) then
            print "   Generators with their orders:";
            for i := 1 to #ed do
                print "    ", gL[i], ",  of order", ed[i];
            end for;
        end if;
        vprintf JacHypTorsion: "\n";
        // Construct the isomorphism from the abstract group to the points on J
        iso := map< G -> J | g :-> &+[ J | s[i]*gL[i] : i in [1..#s]]
                                                    where s := Eltseq(g) >;
        J`TorsionGroup := G; J`TorsionMap := iso;
        t := Cputime(tstart);
        vprintf JacHypTorsion: "Time used for lifting: %o ms\n", Round(1000*tlift);
        vprintf JacHypTorsion: "Total time:            %o ms\n\n", Round(1000*t);
        return G, iso;
    else //Degree(f) eq 7
        return G;
    end if;
end intrinsic;


/* References
[1] Michael Stoll - On the Height constant for curves of genus two.
[2] P. Lockhart - On the Discriminant of Hyperelliptic Curves.
[3] Michael Stoll - An Explicit Theory of heights for Hyperelliptic
    Jacobians of Genus Three
[4] J.S. Müller - Explicit Kummer Varieties of hyperelliptic Jacobian Threefolds
[5] E. V. Flynn, N.P. Smart - Canonical Heights of Jacobians of Genus 2 and the infinite
    descent
[6] Michael Stoll - Arithmetic of Hyperelliptic Curves
*/
