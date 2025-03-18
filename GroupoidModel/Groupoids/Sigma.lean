import GroupoidModel.Groupoids.NaturalModelBase
import GroupoidModel.Russell_PER_MS.NaturalModelSigma

universe v u v₁ u₁ v₂ u₂ v₃ u₃

noncomputable section
-- NOTE temporary section for stuff to be moved elsewhere
section ForOther



end ForOther


-- NOTE content for this doc starts here
namespace GroupoidModel

open CategoryTheory NaturalModelBase Opposite Grothendieck.Groupoidal

namespace FunctorOperation

-- TODO: Fix performance issue.
set_option maxHeartbeats 0 in
/-- The formation rule for Σ-types for the ambient natural model `base`
  unfolded into operations between functors.

  For a point `x : Γ`, `(sigma A B).obj x` is the groupoidal Grothendieck
  construction on the composition
  `ι _ x ⋙ B : A.obj x ⥤ Groupoidal A ⥤ Grpd` -/
@[simps] def sigma {Γ : Grpd.{v₂,u₂}} (A : Γ ⥤ Grpd.{v₁,u₁})
    (B : Grothendieck.Groupoidal A ⥤ Grpd.{v₁,u₁})
    : Γ ⥤ Grpd.{v₁,u₁} where
  obj x := Grpd.of (Grothendieck.Groupoidal ((ι _ x) ⋙ B))
  map {x y} f := map (whiskerRight (Grothendieck.ιNatTrans f) B)
    ⋙ pre (ι A y ⋙ B) (A.map f)
  map_id x := by
    let t := @Grothendieck.ιNatTrans _ _
        (A ⋙ Grpd.forgetToCat) _ _ (CategoryStruct.id x)
    have h (a : A.obj x) : B.map (t.app a) =
        eqToHom (by simp [Functor.map_id]) :=
      calc
        B.map (t.app a)
        _ = B.map (eqToHom (by simp [Functor.map_id])) := by
          rw [Grothendieck.ιNatTrans_id_app]
        _ = eqToHom (by simp [Functor.map_id]) := by
          simp [eqToHom_map]
    simp only [map, Grothendieck.Groupoidal.pre, Grpd.id_eq_id, Grothendieck.pre]
    apply CategoryTheory.Functor.ext
    · intro p1 p2 f
      simp only [Grpd.coe_of, Functor.comp_obj, Functor.comp_map, whiskerRight_twice,
        Grothendieck.map_obj_base, Grothendieck.map_obj_fiber, whiskerRight_app,
        Grothendieck.ι_obj, Grothendieck.map_map_base,
        Grothendieck.map_map_fiber, Functor.id_obj, Functor.id_map]
      congr 1
      · simp only [Grpd.map_id_map, Grothendieck.base_eqToHom,
          Grothendieck.comp_base]
      · simp only [Grpd.forgetToCat, id_eq, Functor.comp_map, whiskerRight_twice,
          Grothendieck.map_obj_base, Grothendieck.map_obj_fiber, whiskerRight_app,
          Grothendieck.ι_obj, Grothendieck.fiber_eqToHom, Grothendieck.comp_fiber]
        rw [Functor.congr_hom (h p2.base) f.fiber]
        simp only [Grpd.eqToHom_hom, eqToHom_map, heq_eqToHom_comp_iff,
          eqToHom_comp_heq_iff, comp_eqToHom_heq_iff, heq_comp_eqToHom_iff]
        generalize_proofs _ _ h1
        have h2 : B.map ((ι A x).map (eqToHom h1).base) =
            eqToHom (by simp only [CategoryTheory.Functor.map_id]; rfl) := by
          rw [Grothendieck.eqToHom_base, eqToHom_map, eqToHom_map]
        rw [Functor.congr_hom h2, heq_eqToHom_comp_iff, heq_comp_eqToHom_iff]
        simp only [heq_eq_eq, Grpd.eqToHom_hom]
    · intro p
      simp only [Functor.comp_obj, Grothendieck.map_obj]
      congr 1
      · exact Grpd.map_id_obj
      · simp only [Grpd.forgetToCat, id_eq, whiskerRight_app,
          Functor.comp_map]
        rw [Functor.congr_obj (h p.base) p.fiber]
        simp [Grpd.eqToHom_obj]
  map_comp := by
    intro x y z f g
    have h (a : A.obj x) : B.map ((Grothendieck.ιNatTrans (f ≫ g)).app a)
        = B.map ((Grothendieck.ιNatTrans f).app a)
        ⋙ B.map (eqToHom (by
          simp [Grpd.forgetToCat]))
        ⋙ B.map ((Grothendieck.ιNatTrans g).app ((A.map f).obj a))
        ⋙ B.map (eqToHom (by
          simp [Grpd.forgetToCat, Grpd.comp_eq_comp])) := by
      simp only [Grothendieck.ιNatTrans_comp_app, Functor.map_comp,
        eqToHom_map, CategoryTheory.Functor.map_id]
      rfl
    simp only [Grothendieck.Groupoidal.pre, Grothendieck.pre]
    apply CategoryTheory.Functor.ext
    · sorry
    · intro p
      simp only [Grpd.coe_of, Functor.comp_obj, Functor.comp_map]
      congr 1
      · rw [Grpd.map_comp_obj]
        rfl
      · simp [map, Grpd.forgetToCat, Functor.congr_obj (h p.base) p.fiber,
        eqToHom_refl, eqToHom_map, Grpd.eqToHom_obj, Grpd.id_eq_id, Functor.id_obj]

section

variable {Δ Γ: Grpd.{v₂,u₂}} (σ : Δ ⥤ Γ) (A : Γ ⥤ Grpd.{v₁,u₁})


theorem sigmaBeckChevalley (B : (Grothendieck.Groupoidal A) ⥤ Grpd.{v₁,u₁})
    : σ ⋙ sigma A B = sigma (σ ⋙ A) (pre A σ ⋙ B) := by
  refine CategoryTheory.Functor.ext ?_ ?_
  . intros x
    dsimp only [Functor.comp_obj, sigma_obj]
    rw [← Grothendieck.Groupoidal.ιCompPre σ A x]
    rfl
  . intros x y f
    sorry -- this goal might be improved by adding API for Groupoidal.ι and Groupoidal.pre
end

def GHE {Γ : Cat} {A : Γ ⥤ Cat} {a b : Grothendieck A} {f g : a ⟶ b} (eqb : f.base = g.base) (eqf : f.fiber = (eqToHom (by simp[eqb])) ≫  g.fiber) : f = g := by
  cases f; cases g
  cases eqb
  simp at eqf
  cases eqf
  exact rfl


#check PointedFunctor.congr_point


def eqToHomBase {C : Type} [Category C]{F : C ⥤ Cat} {X Y : Grothendieck F} (h : X = Y) : (eqToHom h).base = eqToHom (congrArg (fun(x) => x.base) h) := by
  rcases h
  simp

def pairSection {Γ : Grpd.{v₂,u₂}} (α β : Γ ⥤ PGrpd.{v₁,u₁})
    (B : Grothendieck.Groupoidal (α ⋙ PGrpd.forgetToGrpd) ⥤ Grpd.{v₁,u₁})
    (h : β ⋙ PGrpd.forgetToGrpd = Grothendieck.Groupoidal.sec α ⋙ B)
    : Γ ⥤ (Grothendieck.Groupoidal (sigma (α ⋙ PGrpd.forgetToGrpd) B)) where
    obj x := by
      fconstructor
      . exact x
      . fconstructor
        . exact (α.obj x).str.pt
        . dsimp[Grpd.forgetToCat,ι]
          let h' := Functor.congr_obj h x
          dsimp[Grothendieck.Groupoidal.sec] at h'
          exact (eqToHom h').obj ((β.obj x).str.pt)
    map {x y} f := by
      refine {base := f, fiber := {base := (α.map f).point, fiber := ?_}}
      dsimp[Grpd.forgetToCat,Grothendieck.Groupoidal.pre,Grothendieck.pre,ι,map,Grothendieck.ιNatTrans]
      simp[<- Grpd.map_comp_obj,CategoryStruct.comp,Grothendieck.comp,Grpd.forgetToCat]
      have rwn := Eq.trans (Prefunctor.congr_map (Grothendieck.Groupoidal.sec α ⋙ B).toPrefunctor (Category.comp_id f)) (Functor.congr_hom h.symm f)
      simp only [Functor.comp_map,Grothendieck.Groupoidal.sec] at rwn
      rw [<-(PointedFunctor.congr_point (congrArg α.map (id (Category.comp_id f)))),rwn,<- Functor.comp_obj]
      simp only [CategoryStruct.comp,<- Functor.assoc]
      have rwl {a1 a2 a3 : Grpd} {o1 : a1 = a2} {o2 : a2 = a3} : (eqToHom o1) ⋙ (eqToHom o2) = eqToHom (Eq.trans o1 o2) := by
        cases o1; cases o2; simp[Functor.comp,CategoryStruct.id,Functor.id]
      rw [rwl]
      exact (eqToHom (Functor.congr_obj h y)).map (β.map f).point
    map_id x := by
      simp[CategoryStruct.id,Grothendieck.id]
      fapply Grothendieck.ext
      . exact rfl
      . fapply Grothendieck.ext
        . simp
          refine Eq.trans (PointedFunctor.congr_point (α.map_id x)) ?_
          simp [CategoryStruct.id]
          sorry --I dont know why the eqToHomBase Lemma is not working here
        . sorry
    map_comp := by
      intros x y z f g
      simp[CategoryStruct.comp,Grothendieck.comp, Functor.map]


def TypeToShowNatrality {Γ : Grpd.{v₂,u₂}} := (α : Γ ⥤ PGrpd.{v₁,u₁}) × (β : Γ ⥤ PGrpd.{v₁,u₁}) × (B : Grothendieck.Groupoidal (α ⋙ PGrpd.forgetToGrpd) ⥤ Grpd.{v₁,u₁}) ×' (β ⋙ PGrpd.forgetToGrpd = Grothendieck.Groupoidal.sec α ⋙ B)

def TypeToShowNatrality.Hom {Γ : Grpd.{v₂,u₂}} (⟨α,β,B,h⟩ ⟨α',β',B',h'⟩  : TypeToShowNatrality) : Type := (f : α ⟶ α') × (g : β ⟶ β') × (k : B ⟶ B')

def  pairSection_natral_in_α {Γ : Grpd.{v₂,u₂}} (α β : Γ ⥤ PGrpd.{v₁,u₁}) (B : Grothendieck.Groupoidal (α ⋙ PGrpd.forgetToGrpd) ⥤ Grpd.{v₁,u₁}) (h : β ⋙ PGrpd.forgetToGrpd = Grothendieck.Groupoidal.sec α ⋙ B) :

    apply GHE
    . simp[pairSection,sigma]
    . simp[pairSection,sigma]

theorem pairSection_isSection {Γ : Grpd.{v₂,u₂}} (α β : Γ ⥤ PGrpd.{v₁,u₁})
    (B : Grothendieck.Groupoidal (α ⋙ PGrpd.forgetToGrpd) ⥤ Grpd.{v₁,u₁})
    (h : β ⋙ PGrpd.forgetToGrpd = Grothendieck.Groupoidal.sec α ⋙ B) : (pairSection α β B h) ⋙ Grothendieck.forget _ = Functor.id Γ := by
    simp[pairSection,Functor.comp,Functor.id]

def pair {Γ : Grpd.{v₂,u₂}} (α β : Γ ⥤ PGrpd.{v₁,u₁})
    (B : Grothendieck.Groupoidal (α ⋙ PGrpd.forgetToGrpd) ⥤ Grpd.{v₁,u₁})
    (h : β ⋙ PGrpd.forgetToGrpd = Grothendieck.Groupoidal.sec α ⋙ B)
    : Γ ⥤ PGrpd.{v₁,u₁} := pairSection α β B h ⋙ Grothendieck.Groupoidal.toPGrpd _

end FunctorOperation

open FunctorOperation

/-- The formation rule for Σ-types for the ambient natural model `base` -/
def baseSig : base.Ptp.obj base.{u}.Ty ⟶ base.Ty where
  app Γ := fun p =>
    let ⟨A,B⟩ := baseUvPolyTpEquiv p
    yonedaEquiv (yonedaCatEquiv.symm (sigma A B))
  naturality := sorry -- do not attempt

def basePair : base.uvPolyTp.compDom base.uvPolyTp ⟶ base.Tm where
  app Γ := fun ε =>
    let ⟨α,β,B,h⟩ := baseUvPolyTpCompDomEquiv ε
    yonedaEquiv (yonedaCatEquiv.symm (pair α β B h))
  naturality := by sorry











def baseSigma : NaturalModelSigma base where
  Sig := baseSig
  pair := basePair
  Sig_pullback := sorry -- should prove using the `IsMegaPullback` strategy

def smallUSigma : NaturalModelSigma smallU := sorry

def uHomSeqSigmas' (i : ℕ) (ilen : i < 4) :
  NaturalModelSigma (uHomSeqObjs i ilen) :=
  match i with
  | 0 => smallUSigma
  | 1 => smallUSigma
  | 2 => smallUSigma
  | 3 => baseSigma
  | (n+4) => by omega

def uHomSeqSigmas : UHomSeqSigmas Ctx := {
  uHomSeq with
  Sigmas' := uHomSeqSigmas' }

end GroupoidModel

end
