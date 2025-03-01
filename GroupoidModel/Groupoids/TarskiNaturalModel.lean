import Mathlib.CategoryTheory.Limits.Preserves.FunctorCategory
import GroupoidModel.Tarski.NaturalModel
import GroupoidModel.Grothendieck.IsPullback
import GroupoidModel.Grothendieck.Groupoidal
import Poly.LCCC.Basic
import Poly.LCCC.Presheaf
import Poly.Exponentiable
import Poly.Polynomial

/-!
Here we construct the natural model for groupoids.

TODO: This file needs to eventually be ported to GroupoidRussellNaturalModel
but currently we don't have a Russell style sigma type.
-/

universe u v u₁ v₁ u₂ v₂

open CategoryTheory ULift

noncomputable section

section

section
/-
Grpd.{u, u} is
the category of
{small groupoids - size u objects and size u hom sets}
which itself has size u+1 objects (small groupoids)
and size u hom sets (functors).
We want this to be a small category so we lift the homs.
-/
def sGrpd := ULiftHom.{u+1} Grpd.{u,u}
  deriving SmallCategory

def sGrpd.of (C : Type u) [Groupoid.{u} C] : sGrpd.{u} := Grpd.of C

def CatLift : Cat.{u,u} ⥤ Cat.{u,u+1} where
    obj x := Cat.of (ULift.{u + 1, u} x)
    map {x y} f := downFunctor ⋙ f ⋙ upFunctor

@[simp] def sGrpd.forget : sGrpd.{u} ⥤ Grpd.{u,u} := ULiftHom.down

def sGrpd.remember : Grpd.{u,u} ⥤ sGrpd.{u} := ULiftHom.up

variable (C D) [Category.{u} C] [Category.{u} D]

def ι : Grpd.{u, u} ⥤ Cat.{u,u+1} := Grpd.forgetToCat ⋙ CatLift

def PshGrpdOfCat : Cat.{u,u+1} ⥤ (Grpd.{u,u}ᵒᵖ ⥤ Type (u + 1)) :=
  yoneda ⋙ (whiskeringLeft _ _ _).obj ι.op

def PshsGrpdOfPshGrpd : (Grpd.{u,u}ᵒᵖ ⥤ Type (u + 1)) ⥤ (sGrpd.{u}ᵒᵖ ⥤ Type (u + 1)) :=
  (whiskeringLeft _ _ _).obj sGrpd.forget.op

abbrev yonedaCat : Cat.{u, u+1} ⥤ Psh sGrpd.{u} :=
  PshGrpdOfCat ⋙ PshsGrpdOfPshGrpd

end

section

variable {Γ Δ : sGrpd.{u}}
  {C D : Type (u+1)} [Category.{u,u+1} C][Category.{u,u+1} D]

/- The bijection y(Γ) → [-,C]   ≃   Γ ⥤ C -/
@[simp] def yonedaCatEquiv :
  (yoneda.obj Γ ⟶ yonedaCat.obj (Cat.of C))
  ≃ (sGrpd.forget.obj Γ) ⥤ C :=
  Equiv.trans yonedaEquiv
    {toFun     := λ A ↦ ULift.upFunctor ⋙ A
     invFun    := λ A ↦ ULift.downFunctor ⋙ A
     left_inv  := λ _ ↦ rfl
     right_inv := λ _ ↦ rfl}

theorem yonedaCatEquiv_naturality
  (A : yoneda.obj Γ ⟶ yonedaCat.obj (Cat.of C)) (σ : Δ ⟶ Γ) :
  (sGrpd.forget.map σ) ⋙ yonedaCatEquiv A
    = yonedaCatEquiv (yoneda.map σ ≫ A) := by
  simp[← yonedaEquiv_naturality]
  rfl

theorem yonedaCatEquiv_comp
  (A : yoneda.obj Γ ⟶ yonedaCat.obj (Cat.of D)) (U : D ⥤ C) :
  yonedaCatEquiv (A ≫ yonedaCat.map U) = yonedaCatEquiv A ⋙ U := by
  aesop_cat


abbrev Ty : Psh sGrpd.{u} := yonedaCat.obj (Cat.of Grpd.{u,u})

abbrev Tm : Psh sGrpd.{u} := yonedaCat.obj (Cat.of PGrpd.{u,u})

variable {Γ : sGrpd.{u}} (A : yoneda.obj Γ ⟶ Ty)

abbrev tp : Tm ⟶ Ty := yonedaCat.map (PGrpd.forgetToGrpd)

abbrev ext : Grpd.{u,u} := Grpd.of (Grothendieck.Groupoidal (yonedaCatEquiv A))

abbrev downDisp : ext A ⟶ (Γ : Grpd.{u,u}) := Grothendieck.forget _

abbrev disp : @Quiver.Hom sGrpd _ (ext A) Γ := { down := downDisp A }

abbrev var : (yoneda.obj (ext A) : Psh sGrpd) ⟶ Tm :=
  yonedaCatEquiv.invFun (sorry)

theorem disp_pullback :
    IsPullback (var A) (yoneda.map { down := downDisp A }) tp A := sorry

end

-- PLAN

-- show that yonedaCat preserves IsPullback
-- show that yoneda : sGrpd ⥤ Psh sGrpd factors through yonedaCat (up to a natural iso)
-- show that desired pullback is two squares (the natural iso and the image of the grothendieck pullback in Cat under yonedaCat)
-- prove the grothendieck pullback is a pullback

instance GroupoidNM : NaturalModel.NaturalModelBase sGrpd.{u} where
  Ty := Ty
  Tm := Tm
  tp := tp
  ext _ A := sGrpd.of (ext A)
  disp _ A := disp A
  var _ A := var A
  disp_pullback A := disp_pullback A

instance groupoidULift.{u'} {α : Type u} [Groupoid.{v} α] : Groupoid (ULift.{u'} α) where
  inv f := Groupoid.inv f
  inv_comp _ := Groupoid.inv_comp ..
  comp_inv _ := Groupoid.comp_inv ..

instance groupoidULiftHom.{u'} {α : Type u} [Groupoid.{v} α] : Groupoid (ULiftHom.{u'} α) where
  inv f := .up (Groupoid.inv f.down)
  inv_comp _ := ULift.ext _ _ <| Groupoid.inv_comp ..
  comp_inv _ := ULift.ext _ _ <| Groupoid.comp_inv ..

inductive Groupoid2 : Type (u+2) where
  | small (_ : sGrpd.{u})
  | large (_ : sGrpd.{u+1})

def Groupoid2.toLarge : Groupoid2.{u} → sGrpd.{u+1}
  | .small A => .mk (ULiftHom.{u+1} (ULift.{u+1} A.α))
  | .large A => A

/-- A model of Grpd with an internal universe, with the property that the small universe
injects into the large one. -/
def Grpd2 : Type (u+2) := InducedCategory sGrpd.{u+1} Groupoid2.toLarge
  deriving SmallCategory

section NaturalModelSigma


def PointToFiber {Γ : Grpd} (A : Γ ⥤ Grpd) (x : Γ) : (A.obj x) ⥤ Grothendieck.Groupoidal A where
  obj a := { base := x, fiber := a }
  map f := by
    fconstructor
    . exact 𝟙 x
    . rename_i X Y
      dsimp [Grpd.forgetToCat]
      let h : X = (A.map (𝟙 x)).obj X := by
        simp[CategoryStruct.id]
      refine eqToHom h.symm ≫ ?_
      exact f
  map_comp f g := by
    fapply Grothendieck.ext
    . simp
    . simp [Grpd.forgetToCat,eqToHom_map]
      rename_i X Y Z
      let h' : X = (A.map (𝟙 x ≫ 𝟙 x)).obj X := by
        simp[CategoryStruct.id]
      simp [<- Category.assoc]
      refine (congrFun (congrArg CategoryStruct.comp ?_) g)
      simp [Category.assoc]
      have ee : Epi (eqToHom h') := by
        exact IsIso.epi_of_iso (eqToHom h')
      apply ee.left_cancellation
      simp
      refine @IsHomLift.fac _ _ _ _ _ _ _ _ _ f f ?_
      constructor; simp; constructor

def  PointToFiberNT {Γ : Grpd} (A : Γ ⥤ Grpd) (X Y : Γ) (f : X ⟶ Y) : PointToFiber A X ⟶ ((A.map f) ⋙ (PointToFiber A Y)) where
  app x := by
    fconstructor
    . simp[PointToFiber]
      exact f
    . simp [Grpd.forgetToCat,PointToFiber]
      exact 𝟙 ((A.map f).obj x)
  naturality X Y f := by
    simp[PointToFiber,CategoryStruct.comp,Grothendieck.comp]
    fapply Grothendieck.ext
    . simp
    . simp[Grpd.forgetToCat, eqToHom_map]

def GroupoidSigma (Γ : Grpd) (A : Γ ⥤ Grpd) (B : (Grothendieck.Groupoidal A) ⥤ Grpd) : Γ ⥤ Grpd where
  obj x := Grpd.of (Grothendieck.Groupoidal ((PointToFiber A x) ⋙ B))
  map f := by
    rename_i X Y
    have NT' : (PointToFiber A X) ⋙ (B ⋙ Grpd.forgetToCat) ⟶ (A.map f ⋙ PointToFiber A Y) ⋙ (B ⋙ Grpd.forgetToCat) := whiskerRight (PointToFiberNT A X Y f) (B ⋙ Grpd.forgetToCat)
    exact (Grothendieck.map NT') ⋙ (Grothendieck.Groupoidal.functorial (A.map f) (PointToFiber A Y ⋙ B))
  map_id := by
    intro X
    simp[CategoryStruct.id,whiskerRight,Functor.id]
    refine CategoryTheory.Functor.ext ?_ ?_
    . intro X
      simp[PointToFiber,Grpd.forgetToCat]
      sorry
    all_goals sorry
  map_comp := by
    intro X Y Z f g
    simp[Grpd.forgetToCat]
    sorry

def GroupoidSigmaBase (Γ : Grpd) (A : Γ ⥤ Grpd) (B : (Grothendieck.Groupoidal A) ⥤ Grpd) : (GroupoidSigma Γ A B) ⟶ A := by
  fconstructor
  . dsimp [GroupoidSigma]
    intro x
    dsimp[Quiver.Hom]
    exact Grothendieck.forget (Grpd.compForgetToCat (PointToFiber A x ⋙ B))
  . intros X Y f
    exact rfl


def GroupoidPair (Γ : Grpd) (A : Γ ⥤ Grpd) (B : (Grothendieck.Groupoidal A) ⥤ PGrpd) : Γ ⥤ PGrpd where
  obj x := by
    refine @PGrpd.of ((GroupoidSigma Γ A (B ⋙ PGrpd.forgetToGrpd)).obj x).α ?_
    fconstructor
    dsimp [GroupoidSigma]
    fconstructor
    . sorry
    sorry

theorem GroupoidSigmaBeckChevalley (Δ Γ: Grpd.{v,u}) (σ : Δ ⥤ Γ) (A : Γ ⥤ Grpd.{v,u})
  (B : (Grothendieck.Groupoidal A) ⥤ Grpd.{v,u}) : σ ⋙ GroupoidSigma Γ A B = GroupoidSigma _ (σ ⋙ A)
  (Grothendieck.Groupoidal.Map Δ Γ σ A B) := by
  refine CategoryTheory.Functor.ext ?_ ?_
  . intros X
    sorry
  . intros X Y f
    sorry

def uv_tp : UvPoly Tm.{u} Ty.{u} where
  p := tp

def P : Psh sGrpd ⥤ Psh sGrpd := uv_tp.functor.{u}

instance : Limits.HasLimits (Psh sGrpd) := by
  infer_instance

instance {Γ : sGrpd} (A : yoneda.obj Γ ⟶ Ty): Limits.HasLimit (Limits.cospan A uv_tp.p) := by
  infer_instance

def Limits_Sub {Γ : sGrpd} (A : yoneda.obj Γ ⟶ Ty): Limits.pullback A uv_tp.p ≅ yoneda.obj (GroupoidNM.ext _ A) := by
  refine ((IsPullback.isoPullback (snd := (NaturalModel.var Γ A)) (fst := yoneda.map (NaturalModel.disp Γ A))) ?_).symm
  have isPB := GroupoidNM.disp_pullback A
  exact IsPullback.flip isPB

def GroupoidNMSigma : (P.obj.{u} Ty.{u}) ⟶ Ty.{u} := by
  fconstructor
  . dsimp [Quiver.Hom]
    intros sObj poly
    let poly' := yonedaEquiv.invFun poly
    let poly_as_pair := (UvPoly.equiv uv_tp (yoneda.obj (Opposite.unop sObj)) Ty).toFun poly'
    rcases poly_as_pair with ⟨A, B⟩
    have B := yonedaEquiv.toFun ((Limits_Sub A).inv ≫ B)
    exact downFunctor ⋙ (GroupoidSigma (sGrpd.forget.obj (Opposite.unop sObj)) (upFunctor ⋙ (yonedaEquiv.toFun A)) (upFunctor ⋙ B))
  . intros X Y f
    funext a
    refine CategoryTheory.Functor.ext ?_ ?_
    . intro b
      sorry
    . intros b₁ b₂ g
      sorry


#check UvPoly.Hom.comp tp tp

def GroupoidNMPair : (P.obj.{u} Tm.{u}) ⟶ Tm.{u} := by
  fconstructor
  . intros sObj poly
    have OITy := GroupoidNMSigma.app _ ((P.map tp).app _ poly)
    let poly' := yonedaEquiv.invFun poly
    let poly_as_pair := (UvPoly.equiv uv_tp (yoneda.obj (Opposite.unop sObj)) Tm).toFun poly'
    rcases poly_as_pair with ⟨A, B⟩
    have B := yonedaEquiv.toFun ((Limits_Sub A).inv ≫ B)
    dsimp [PshsGrpdOfPshGrpd,PshGrpdOfCat] at B
    exact downFunctor ⋙ (GroupoidPair (sGrpd.forget.obj (Opposite.unop sObj)) (upFunctor ⋙ (yonedaEquiv.toFun A)) (upFunctor ⋙ B))
  . sorry



def GroupoidNMSigmaPullback : IsPullback GroupoidNMPair (P.map tp) tp GroupoidNMSigma := by sorry

end NaturalModelSigma
section NaturalModelPi

instance (C : Type) [Category C] (P : C → Prop) : Category {x : C // P x} where
  Hom x y := x.1 ⟶ y.1
  id x := 𝟙 x.1
  comp f g := f ≫ g

instance g (C : Type) [Groupoid C] (P : C → Prop) : Groupoid {x : C // P x} where
  inv f := Groupoid.inv f
  inv_comp _ := Groupoid.inv_comp ..
  comp_inv _ := Groupoid.comp_inv ..

instance (G1 G2 : Type) [Groupoid G1] [Groupoid G2] : Groupoid (G1 ⥤ G2) where
  inv f := by
    rename_i X Y
    fconstructor
    . intro x
      have t := f.app x
      exact Groupoid.inv t
    . simp


def GroupoidPiMap (Γ : Grpd) (A : Γ ⥤ Grpd) (B : (Grothendieck.Groupoidal A) ⥤ Grpd) : Γ ⥤ Grpd where
  obj x := Grpd.of (A.obj x ⥤ (GroupoidSigma Γ A B).obj x)
  map f := by
    dsimp[Quiver.Hom]
    rename_i X Y
    fconstructor
    fconstructor
    . intro F
      exact A.map (Groupoid.inv f) ⋙ F ⋙ ((GroupoidSigma Γ A B).map f)
    . intros X' Y' f'
      fconstructor
      . intro x
        refine ((GroupoidSigma Γ A B).map f).map (f'.app _)
      . intros X' Y' f'
        dsimp
        congr 2




    sorry

def GroupoidPi (Γ : Grpd) (A : Γ ⥤ Grpd) (B : (Grothendieck.Groupoidal A) ⥤ Grpd) : Γ ⥤ Grpd where
  obj x := by
    have t := g (A.obj x ⥤ (GroupoidSigma Γ A B).obj x) (fun(f) => f ⋙ ((GroupoidSigmaBase Γ A B).app x) = 𝟙 (A.obj x))
    exact Grpd.of {f : A.obj x ⥤ (GroupoidSigma Γ A B).obj x // f ⋙ ((GroupoidSigmaBase Γ A B).app x) = 𝟙 (A.obj x)}
  map f := by
    dsimp[Quiver.Hom]
    rename_i X Y
    sorry

    -- have F : ((A.obj X) ⥤ ((GroupoidSigma Γ A B).obj X)) ⥤ ((A.obj Y) ⥤ ((GroupoidSigma Γ A B).obj Y)) := by
    --   fconstructor
    --   fconstructor
    --   . intro

    -- fconstructor
    -- fconstructor
    -- . intro x
    --   rcases x with ⟨x, hx⟩
    --   fconstructor
    --   . exact A.map (Groupoid.inv f) ⋙ x ⋙ ((GroupoidSigma Γ A B).map f)
    --   . simp at hx



end NaturalModelPi

section NaturalModelEq

end NaturalModelEq

end
