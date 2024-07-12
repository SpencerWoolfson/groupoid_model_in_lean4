/-
Copyright (c) 2024 Sina Hazratpour. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sina Hazratpour
-/

import Mathlib.CategoryTheory.Category.Preorder
import GroupoidModel.FibrationForMathlib.Displayed.Fiber

/-!
# Displayed category

Given a type family `F : C → Type*` on a category `C` we define the type class `Display F`
of displayed categories over `F`. A displayed category structure associates to each morphism `f`
in `C`  and terms `X : F I` and `Y : F J` a type `HomOver f X Y`.
We think of `F I` as the Fiber over `I`, and we think of `HomOver f X Y` as the type ofmorphisms
lying over `f` starting from `X` and ending at `Y`. The data of a displayed category structure
also provides the dependent operations of identity and composition for `HomOver`.
Finally, the modified laws of associativity and unitality hold dependently over the associativity and unitality equalities in `C`.

## Main results

Our main construction is the displayed category of a functor. Given a functor `P : E ⥤ C`, the associated displayed category on the Fiber family `fun c => P⁻¹ c` is provided by the instance `Functor.display`. Here `HomOver f X Y ` is given by the type `BasedLift f src tgt` carrying data witnessing morphisms in `E` starting from `src` and ending at `tgt` and are mapped to `f` under `P`.

We also provide various useful constructors for based-lifts:
* `BasedLift.tauto` regards a morphism `g` of the domain category `E` as a
  tautological based-lift of its image `P.map g`.
* `BasedLift.id` and `BasedLift.comp` provide the identity and composition of
  based-lifts, respectively.
* We can cast a based-lift along an equality of the base morphisms using the equivalence `BasedLift.cast`.

### Notation

We provide the following notations:
* `X ⟶[f] Y` for `DisplayStruct.HomOver f x y`
* `f ≫ₗ g` for `DisplayStruct.comp_over f g`
* `𝟙ₗ X` for `DisplayStruct.id_over`

#### References

Benedikt Ahrens, Peter LeFanu Lumsdaine, Displayed Categories, Logical Methods in Computer Science 15 (1).
-/


namespace CategoryTheory

open Category CategoryTheory

variable {C : Type*} [Category C] (F : C → Type*)


section cast

/-- Cast an element of a Fiber along an equality of the base objects. -/
def FiberCast {I I' : C} (w : I = I') (X : F I)  : F I' :=
  w ▸ X

/-- Tranporsting a morphism `f : I ⟶ J` along equalities `w : I = I'` and  `w' : J = J'`.
Note: It might be a good idea to add this to eqToHom file. -/
@[simp]
def eqToHomMap {I I' J J' : C} (w : I = I') (w' : J = J') (f : I ⟶ J) : I' ⟶ J' :=
  w' ▸ (w ▸ f) --eqToHom (w.symm) ≫ f ≫ eqToHom w'

@[simp]
def eqToHomMapId {I I' : C} (w : I = I') : w ▸ 𝟙 I = 𝟙 I' := by
  subst w
  rfl

@[simp]
lemma eqToHomMap_naturality {I I' J J' : C} {w : I = I'} {w' : J = J'} (f : I ⟶ J) :
    eqToHom w ≫ eqToHomMap w w' f = f ≫ eqToHom w' := by
  subst w' w
  simp

@[simp]
lemma Fiber_cast_trans {I I' I'': C} (X : F I) {w : I = I'} {w' : I' = I''} {w'' : I = I''} :
    w' ▸ (w ▸ X) = w'' ▸ X := by
  subst w'
  rfl

lemma Fiber_cast_cast {I I' : C} (X : F I) {w : I = I'} {w' : I' = I} : w' ▸ w ▸ X = X := by
  simp only [Fiber_cast_trans]

end cast

class DisplayStruct where
  /-- The type of morphisms indexed over morphisms of `C`. -/
  HomOver : ∀ {I J : C}, (I ⟶ J) → F I → F J → Type*
  /-- The identity morphism overlying the identity morphism of `C`. -/
  id_over : ∀ {I : C} (X : F I), HomOver (𝟙 I) X X
  /-- Composition of morphisms overlying composition of morphisms of `C`. -/
  comp_over : ∀ {I J K : C} {f₁ : I ⟶ J} {f₂ : J ⟶ K} {X : F I} {Y : F J}
  {Z : F K}, HomOver f₁ X Y → HomOver f₂ Y Z → HomOver (f₁ ≫ f₂) X Z

notation X " ⟶[" f "] " Y => DisplayStruct.HomOver f X Y
notation "𝟙ₗ" => DisplayStruct.id_over
scoped infixr:80 "  ≫ₗ "  => DisplayStruct.comp_over

class Display extends DisplayStruct F where
  id_comp_cast {I J : C} {f : I ⟶ J} {X : F I} {Y : F J}
  (g : X ⟶[f] Y) : (𝟙ₗ X) ≫ₗ g = (id_comp f).symm ▸ g := by aesop_cat
  comp_id_cast {I J : C} {f : I ⟶ J} {X : F I} {Y : F J}
  (g : X ⟶[f] Y) : g ≫ₗ (𝟙ₗ Y) = ((comp_id f).symm ▸ g) := by aesop_cat
  assoc_cast {I J K L : C} {f₁ : I ⟶ J} {f₂ : J ⟶ K} {f₃ : K ⟶ L} {X : F I}
  {Y : F J} {Z : F K} {W : F L} (g₁ : X ⟶[f₁] Y)
  (g₂ : Y ⟶[f₂] Z) (g₃ : Z ⟶[f₃] W) :
  (g₁ ≫ₗ g₂) ≫ₗ g₃ = (assoc f₁ f₂ f₃).symm ▸ (g₁ ≫ₗ (g₂ ≫ₗ g₃)) := by aesop_cat

attribute [simp] Display.id_comp_cast Display.comp_id_cast Display.assoc_cast
attribute [trans] Display.assoc_cast

namespace Display

variable {F}
variable [Display F]

@[simp]
def cast {I J : C} {f f' : I ⟶ J} {X : F I} {Y : F J} (w : f = f') (g : X ⟶[f] Y) :
    X ⟶[f'] Y :=
  w ▸ g

@[simp]
lemma cast_symm {I J : C} {f f' : I ⟶ J} {X : F I} {Y : F J} (w : f = f') (g : X ⟶[f] Y) (g' : X ⟶[f'] Y) :
    (w ▸ g = g') ↔ g = w.symm ▸ g' := by
  subst w
  rfl

lemma cast_assoc_symm {I J K L : C} {f₁ : I ⟶ J} {f₂ : J ⟶ K} {f₃ : K ⟶ L}
    {X : F I} {Y : F J} {Z : F K} {W : F L} (g₁ : X ⟶[f₁] Y)
    (g₂ : Y ⟶[f₂] Z) (g₃ : Z ⟶[f₃] W) :
    (assoc f₁ f₂ f₃) ▸ ((g₁ ≫ₗ g₂) ≫ₗ g₃) = (g₁ ≫ₗ (g₂ ≫ₗ g₃)) := by
  simp only [cast_symm, assoc_cast]

@[simp]
lemma cast_trans {I J : C} {f f' f'' : I ⟶ J} {X : F I} {Y : F J} {w : f = f'}
    {w' : f' = f''} (g : X ⟶[f] Y) : w' ▸ w ▸ g = (w.trans w') ▸ g := by
  subst w'
  rfl

lemma cast_eq {I J : C} {f f' : I ⟶ J} {X : F I} {Y : F J} {w w' : f = f'} (g : X ⟶[f] Y) :
    w ▸ g = w' ▸ g := by
  rfl

lemma cast_cast{I J : C} {f f' : I ⟶ J} {X : F I} {Y : F J} (w : f = f') (w' : f' = f)
    (g : X ⟶[f'] Y) :
    w' ▸ w ▸ g = g := by
  simp only [cast_trans]

lemma comp_id_eq_cast_id_comp {I J : C} {f : I ⟶ J} {X : F I} {Y : F J} (g : X ⟶[f] Y) :
    g ≫ₗ 𝟙ₗ Y = cast (by simp) (𝟙ₗ X  ≫ₗ g) := by
  simp only [comp_id_cast, cast, id_comp_cast, comp_id, cast_trans]

/-- `EqToHom w X` is a hom-over `eqToHom w` from `X` to `w ▸ X`. -/
def eqToHom {I I' : C} (w : I = I') (X : F I) : X ⟶[eqToHom w] (w ▸ X) := by
  subst w
  exact 𝟙ₗ X

@[simp]
def eqToHomMap {I I' J J' : C} (w : I = I') (w' : J = J') {f : I ⟶ J} {X : F I } {Y : F J}
    (g : X ⟶[f] Y) :
    (w ▸ X) ⟶[eqToHomMap w w' f] (w' ▸ Y) := by
  subst w
  subst w'
  exact g

@[simp]
def eqToHomMapId {I I' : C} (w : I = I') {X : F I } {Y : F I} (g : X ⟶[𝟙 I] Y) :
    (w ▸ X) ⟶[𝟙 I'] (w ▸ Y) := by
  subst w
  exact g

lemma eqToHom_naturality {I I' J J': C} {X : F I} {Y : F J} (w : I = I') (w' : J = J')
    (f : I ⟶ J) (g : X ⟶[f] Y) :
    g ≫ₗ eqToHom w' Y = cast (eqToHomMap_naturality f) (eqToHom w X ≫ₗ eqToHomMap w w' g)  := by
  subst w' w
  simp only [eqToHom, comp_id_eq_cast_id_comp, cast]
  rfl

@[simps!]
def castEquiv {I J : C} {f f' : I ⟶ J} {X : F I} {Y : F J} (w : f = f') :
    (X ⟶[f] Y) ≃ (X ⟶[f'] Y) where
  toFun := fun g ↦ w ▸ g
  invFun := fun g ↦ w.symm ▸ g
  left_inv := by aesop_cat
  right_inv := by aesop_cat

variable (F)

/-- The total space of a displayed category consists of pairs `(I, X)` where `I` is an object of `C` and `X` is an object of the Fiber `F I`. -/
def Total := Σ I : C, F I

prefix:75 " ∫ "  => Total

variable {F}

abbrev TotalHom (X Y : ∫ F) := Σ (f : X.1 ⟶ Y.1), X.2 ⟶[f] Y.2

namespace Total

@[simp]
instance categoryStruct : CategoryStruct (∫ F) where
  Hom := TotalHom
  id X := ⟨𝟙 X.1, 𝟙ₗ X.2⟩
  comp u u' := ⟨u.1 ≫ u'.1, u.2 ≫ₗ u'.2⟩

@[simp]
lemma cast_exchange_comp {I J K : C} {f f' : I ⟶ J} {h h' : J ⟶ K} {X : F I} {Y : F J} {Z : F K}
    (g : X ⟶[f] Y) (k : Y ⟶[h] Z) (w : f = f') (w' : h = h') :
    w' ▸ (g ≫ₗ k) = (w ▸ g) ≫ₗ (w' ▸ k) := by
  subst w w'
  rfl

@[simp]
lemma whisker_left_cast_comp {I J K : C} {f : I ⟶ J} {h h' : J ⟶ K} {X : F I} {Y : F J} {Z : F K}
    (g : X ⟶[f] Y) (k : Y ⟶[h] Z) (w : h = h') : (f ≫= w) ▸ (g ≫ₗ k) = g ≫ₗ (w ▸ k) := by
  subst w
  rfl

@[simp]
lemma whisker_right_cast_comp {I J K : C} {f f' : I ⟶ J} {h : J ⟶ K} {X : F I} {Y : F J} {Z : F K}
    (g : X ⟶[f] Y) (k : Y ⟶[h] Z) (w : f = f') : (w =≫ h) ▸ (g ≫ₗ k) = (w ▸ g) ≫ₗ k := by
  subst w
  rfl

instance category : Category (∫ F) where
  id_comp := by
    rintro ⟨I, X⟩ ⟨J, Y⟩ ⟨f, g⟩
    dsimp
    refine Sigma.eq ?_ ?_
    simp only [id_comp]
    simp only [id_comp_cast, cast_trans]
  comp_id := by
    rintro ⟨I, X⟩ ⟨J, Y⟩ ⟨f, g⟩
    dsimp
    refine Sigma.eq ?_ ?_
    simp only [comp_id]
    simp only [comp_id_cast, cast_trans]
  assoc := by
    rintro ⟨I, X⟩ ⟨J, Y⟩ ⟨K, Z⟩ ⟨L, W⟩ ⟨f, g⟩ ⟨h, k⟩ ⟨l, m⟩
    dsimp
    refine Sigma.eq ?_ ?_
    simp only [assoc]
    simp only [assoc_cast, cast_trans]

end Total

end Display

variable {E : Type*} [Category E] {P : E ⥤ C}

/-- The type of lifts of a given morphism in the base
with fixed source and target in the Fibers of the domain and codomain respectively.-/
structure BasedLift {I J : C} (f : I ⟶ J) (X : P⁻¹ I) (Y : P⁻¹ J) where
  hom : (X : E) ⟶ (Y : E)
  over_eq : (P.map hom) ≫ eqToHom (Y.2) = eqToHom (X.2) ≫ f

/--
The structure of based-lifts up to an isomorphism of the domain objects in the base.
```                   g
     X -------------------------------> Y
     _                                  -
     |                                  |
     |                                  |
     v                                  v
P.obj X --------> I ------> J ----> P.obj Y
            ≅           f       ≅
```
-/
structure EBasedLift {I J : C} (f : I ⟶ J) (X : P⁻¹ᵉ I) (Y : P⁻¹ᵉ J) where
  hom : X.obj ⟶ Y.obj
  iso_over_eq : (P.map hom) ≫ Y.iso.hom = X.iso.hom ≫ f := by aesop_cat

attribute [reassoc] EBasedLift.iso_over_eq

namespace BasedLift

variable {E : Type*} [Category E] {P : E ⥤ C}

@[simp]
lemma over_base {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} (g : BasedLift f X Y) :
    P.map g.hom = eqToHom (X.2) ≫ f ≫ (eqToHom (Y.2).symm)  := by
  simp only [← Category.assoc _ _ _, ← g.over_eq, assoc, eqToHom_trans, eqToHom_refl, comp_id]

/-- The identity based-lift. -/
@[simps!]
def id {I : C} (X : P⁻¹ I) : BasedLift (𝟙 I) X X := ⟨𝟙 _, by simp⟩

/-- The composition of based-lifts -/
@[simps]
def comp {I J K : C} {f₁ : I ⟶ J} {f₂ : J ⟶ K} {X : P⁻¹ I} {Y : P⁻¹ J} {Z : P⁻¹ K}
    (g₁ : BasedLift f₁ X Y) (g₂ : BasedLift f₂ Y Z) :
    BasedLift (f₁ ≫ f₂) X Z :=
  ⟨g₁.hom ≫ g₂.hom, by simp only [P.map_comp]; rw [assoc, over_base g₁, over_base g₂]; simp⟩

@[simps!]
def cast {I J : C} {f f' : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} (w : f = f')
  (g : BasedLift f X Y) : BasedLift f' X Y := ⟨g.hom, by rw [←w, g.over_eq]⟩

end BasedLift

namespace EBasedLift

@[simp]
lemma iso_over_eq' {I J : C} {f : I ⟶ J} {X : P⁻¹ᵉ I} {Y : P⁻¹ᵉ J} (g : EBasedLift f X Y) :
    P.map g.hom = X.iso.hom ≫ f ≫ Y.iso.inv := by
  simpa using g.iso_over_eq_assoc (Y.iso.inv)

def id {I : C} (X : P⁻¹ᵉ I) : EBasedLift (𝟙 I) X X where
  hom := 𝟙 _

def comp {I J K : C} {f₁ : I ⟶ J} {f₂ : J ⟶ K} {X : P⁻¹ᵉ I} {Y : P⁻¹ᵉ J} {Z : P⁻¹ᵉ K}
    (g₁ : EBasedLift f₁ X Y) (g₂ : EBasedLift f₂ Y Z) :
    EBasedLift (f₁ ≫ f₂) X Z := by
  refine ⟨g₁.hom ≫ g₂.hom, ?_⟩
  have := by
    calc
      P.map (g₁.hom ≫ g₂.hom) = P.map (g₁.hom) ≫ P.map (g₂.hom) := by
        rw [P.map_comp]
      _   = (X.iso.hom ≫ f₁ ≫ Y.iso.inv) ≫ P.map (g₂.hom) := by
        rw [g₁.iso_over_eq']
      _   = X.iso.hom ≫ f₁ ≫ (Y.iso.inv ≫ P.map (g₂.hom)) := by
        simp only [iso_over_eq', assoc, Iso.inv_hom_id_assoc]
      _   = X.iso.hom ≫ f₁ ≫ (Y.iso.inv ≫ Y.iso.hom ≫ f₂ ≫ Z.iso.inv) := by
        rw [g₂.iso_over_eq']
      _   = X.iso.hom ≫ f₁ ≫ (𝟙 J ≫ f₂ ≫ Z.iso.inv) := by
        simp
      _   = X.iso.hom ≫ f₁ ≫ f₂ ≫ Z.iso.inv := by
        simp
  simp [this]

@[simps!]
def cast {I J : C} {f f' : I ⟶ J} {X : P⁻¹ᵉ I} {Y : P⁻¹ᵉ J}
    (w : f = f') (g : EBasedLift f X Y) : EBasedLift f' X Y where
  hom := g.hom
  iso_over_eq := by
    rw [←w, g.iso_over_eq]

end EBasedLift

variable (P)

/-- The display structure `DisplayStruct P` associated to a functor `P : E ⥤ C`.
This instance makes the displayed notations `_ ⟶[f] _`, `_ ≫ₗ _` and `𝟙ₗ` available for based-lifts.   -/
instance Functor.displayStruct : DisplayStruct (fun I => P⁻¹ I) where
  HomOver := fun f X Y => BasedLift f X Y
  id_over X := BasedLift.id X
  comp_over := fun g₁ g₂ => BasedLift.comp g₁ g₂

instance Functor.isodisplay : DisplayStruct (fun I => P⁻¹ᵉ I) where
  HomOver := fun f X Y => EBasedLift f X Y
  id_over := fun X => EBasedLift.id X
  comp_over := fun g₁ g₂ => EBasedLift.comp g₁ g₂

namespace BasedLift

variable {P}

@[ext]
theorem ext {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} (g g' : X ⟶[f] Y)
    (w : g.hom = g'.hom)  : g = g' := by
  cases' g with g hg
  cases' g' with g' hg'
  congr

@[simp]
lemma cast_rec {I J : C} {f f' : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} {w : f = f'} (g : X ⟶[f] Y) :
    g.cast w  = w ▸ g := by
  subst w
  rfl

/-- `BasedLift.tauto` regards a morphism `g` of the domain category `E` as a
based-lift of its image `P g` under functor `P`. -/
@[simps!]
def tauto {X Y : E} (g : X ⟶ Y) : (Fiber.tauto X) ⟶[P.map g] (Fiber.tauto Y) :=
  ⟨g, by simp only [Fiber.tauto, eqToHom_refl, id_comp, comp_id]⟩

lemma tauto_over_base {X Y : E} (f : (P.obj X) ⟶ (P.obj Y)) (g : (Fiber.tauto X) ⟶[f] (Fiber.tauto Y)) : P.map g.hom = f := by
  simp only [Fiber.coe_mk, over_base, eqToHom_refl, comp_id, id_comp]

lemma tauto_comp_hom {X Y Z : E} {g : X ⟶ Y} {g' : Y ⟶ Z} :
    (tauto (P:= P) g ≫ₗ tauto g').hom = g ≫ g' := by
  rfl

lemma comp_tauto_hom {X Y Z : E} {f : P.obj X ⟶ P.obj Y} {f' : Fiber.tauto X ⟶[f] (Fiber.tauto Y)}
    {g : Y ⟶ Z} : (f' ≫ₗ tauto g).hom = f'.hom ≫ g := by
  rfl

/-- A morphism of `E` coerced as a tautological based-lift. -/
@[simps]
 instance instCoeTautoBasedLift {X Y : E} {g : X ⟶ Y} :
    CoeDep (X ⟶ Y) (g : X ⟶ Y) (Fiber.tauto X ⟶[P.map g] Fiber.tauto Y) := ⟨tauto g⟩

lemma eq_id_of_hom_eq_id {I : C} {X : P⁻¹ I} {g : X ⟶[𝟙 I] X} :
    (g.hom = 𝟙 X.1) ↔ (g = id X) := by
  aesop

@[simp]
lemma id_comp_cast {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J}
    {g : X ⟶[f] Y} : 𝟙ₗ X  ≫ₗ g = g.cast (id_comp f).symm := by
  ext
  simp only [cast_hom, DisplayStruct.comp_over, DisplayStruct.id_over, comp_hom, id_hom, id_comp]

@[simp]
lemma comp_id_cast {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} {g : X ⟶[f] Y} :
    g ≫ₗ 𝟙ₗ Y = g.cast (comp_id f).symm := by
  ext
  simp only [cast_hom, DisplayStruct.comp_over, DisplayStruct.id_over, comp_hom, id_hom, comp_id]

@[simp]
lemma assoc {I J K L : C} {f : I ⟶ J} {h : J ⟶ K} {l : K ⟶ L} {W : P⁻¹ I} {X : P⁻¹ J} {Y : P⁻¹ K} {Z : P⁻¹ L} (g : W ⟶[f] X) (k : X ⟶[h] Y) (m : Y ⟶[l] Z) : (g ≫ₗ k) ≫ₗ m = (g ≫ₗ (k ≫ₗ m)).cast (assoc f h l).symm := by
  ext
  simp only [cast_hom, DisplayStruct.comp_over, comp_hom, Category.assoc]

end BasedLift

namespace EBasedLift

@[ext]
theorem ext {I J : C} {f : I ⟶ J} {X : P⁻¹ᵉ I} {Y : P⁻¹ᵉ J} (g g' : X ⟶[f] Y)
    (w : g.hom = g'.hom) : g = g' := by
  cases' g with g hg
  cases' g' with g' hg'
  congr

@[simp]
lemma cast_rec {I J : C} {f f' : I ⟶ J} {X : P⁻¹ᵉ I} {Y : P⁻¹ᵉ J}
    {w : f = f'} (g : X ⟶[f] Y) :
    g.cast w  = w ▸ g := by
  subst w
  rfl

/-- `BasedLift.tauto` regards a morphism `g` of the domain category `E` as a
based-lift of its image `P g` under functor `P`. -/
@[simps!]
def tauto {X Y : E} (g : X ⟶ Y) : (EFiber.tauto X) ⟶[P.map g] (EFiber.tauto Y) where
  hom := g
  iso_over_eq := sorry

lemma tauto_over_base {X Y : E} (f : (P.obj X) ⟶ (P.obj Y)) (g : (Fiber.tauto X) ⟶[f] (Fiber.tauto Y)) :
    P.map g.hom = f := by
  sorry

lemma tauto_comp_hom {X Y Z : E} {g : X ⟶ Y} {g' : Y ⟶ Z} :
    (tauto P g ≫ₗ tauto P g').hom = g ≫ g' := by
  rfl

lemma comp_tauto_hom {X Y Z : E} {f : P.obj X ⟶ P.obj Y} {f' : EFiber.tauto X ⟶[f] (EFiber.tauto Y)}
    {g : Y ⟶ Z} : (f' ≫ₗ tauto P g).hom = f'.hom ≫ g := by
  rfl

/-- A morphism of `E` coerced as a tautological based-lift. -/
@[simps]
 instance instCoeTautoBasedLift {X Y : E} {g : X ⟶ Y} :
    CoeDep (X ⟶ Y) (g : X ⟶ Y) (EFiber.tauto X ⟶[P.map g] EFiber.tauto Y) := ⟨tauto P g⟩

lemma eq_id_of_hom_eq_id {I : C} {X : P⁻¹ I} {g : X ⟶[𝟙 I] X} :
    (g.hom = 𝟙 X.1) ↔ (g = 𝟙ₗ X) := by
  aesop

@[simp]
lemma id_comp_cast {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J}
    {g : X ⟶[f] Y} : 𝟙ₗ X ≫ₗ g = g.cast (id_comp f).symm := by
  ext
  simp only [DisplayStruct.comp_over, DisplayStruct.id_over, BasedLift.comp_hom, BasedLift.id_hom, id_comp]
  rfl

@[simp]
lemma comp_id_cast {I J : C} {f : I ⟶ J} {X : P⁻¹ I} {Y : P⁻¹ J} {g : X ⟶[f] Y} :
    g ≫ₗ 𝟙ₗ Y = g.cast (comp_id f).symm := by
  ext
  simp only [cast_hom, DisplayStruct.comp_over, DisplayStruct.id_over, BasedLift.comp_hom, BasedLift.id_hom, comp_id]
  rfl

@[simp]
lemma assoc {I J K L : C} {f : I ⟶ J} {h : J ⟶ K} {l : K ⟶ L}
    {W : P⁻¹ I} {X : P⁻¹ J} {Y : P⁻¹ K} {Z : P⁻¹ L}
    (g : W ⟶[f] X) (k : X ⟶[h] Y) (m : Y ⟶[l] Z) :
    (g ≫ₗ k) ≫ₗ m = (g ≫ₗ (k ≫ₗ m)).cast (assoc f h l).symm := by
  ext
  simp only [cast_hom, DisplayStruct.comp_over, BasedLift.comp_hom, Category.assoc]
  rfl

end EBasedLift



/-- The displayed category of a functor `P : E ⥤ C`. -/
instance Functor.display : Display (fun I => P⁻¹ I) where
  id_comp_cast := by simp  --simp_all only [BasedLift.comp, BasedLift.id, id_comp]; rfl
  comp_id_cast := by
    simp only [BasedLift.comp_id_cast, BasedLift.cast_rec, implies_true]
  assoc_cast := by
    simp only [BasedLift.assoc, BasedLift.cast_rec, implies_true]

instance Functor.isoDisplay : Display (fun I => EFiber P I) where
  id_comp_cast := by
    intro I J f X Y g
    sorry


  comp_id_cast := by sorry
  assoc_cast := by sorry

namespace Display

variable {F}
variable [Display F]

/-- The type `Lift f tgt` of a lift of `f` with the target `tgt` consists of an object `src` in
the Fiber of the domain of `f` and a based-lift of `f` starting at `src` and ending at `tgt`. -/
@[ext]
structure Lift {I J : C} (f : I ⟶ J) (tgt : F J) where
  src : F I
  homOver : src ⟶[f] tgt

/-- The type `CoLift f src` of a colift of `f` with the source `src` consists of an object `tgt` in
the Fiber of the codomain of `f` and a based-lift of `f` starting at `src` and ending at `tgt`. -/
@[ext]
structure CoLift {I J : C} (f : I ⟶ J) (src : F I) where
  tgt : F J
  homOver : src ⟶[f] tgt


end Display

end CategoryTheory
