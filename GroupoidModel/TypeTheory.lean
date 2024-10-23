import GroupoidModel.NaturalModel

set_option autoImplicit true

section RawSyntax

mutual
inductive TyExpr where
  | univ
  | el (A : Expr)
  | pi (A B : TyExpr)
  deriving Repr

inductive Expr where
  /-- A de Bruijn index. -/
  | bvar (n : Nat)
  | app (f a : Expr)
  | lam (ty : TyExpr) (val : Expr)
  | pi (A B : Expr)
  deriving Repr
end

/-! In this section we compute the action of substitutions.

Write `↑ⁿ` for the `n`-fold weakening substitution `{n+i/i}`.
Write `σ:k` for `σ.vₖ₋₁.….v₁.v₀`.

The substitution `↑ⁿ⁺ᵏ:k`,
i.e., `{0/0,…,k-1/k-1, k+n/k,k+1+n/k+1,…}`,
arises by starting with `↑ⁿ` and traversing under `k` binders:
for example, `(ΠA. B)[↑¹] = ΠA[↑¹]. B[↑².v₀]`.

The substitution `↑ᵏ.e[↑ᵏ]:k`,
i.e., `{0/0,…,k-1/k-1, e[↑ᵏ]/k, k/k+1,k+2/k+3,…}`,
arises by starting with `id.e` and traversing under `k` binders:
for example `(ΠA. B)[id.e] = ΠA[id.e]. B[↑.e[↑].v₀]`.

The substitution `id.e` is used in `β`-reduction:
`(λa) b ↝ a[id.b]`. -/
section Substitutions

/-- Evaluate `↑ⁿ⁺ᵏ:k` at a de Bruijn index `i`. -/
def liftVar (n i : Nat) (k := 0) : Nat := if i < k then i else n + i

theorem liftVar_lt (h : i < k) : liftVar n i k = i := if_pos h
theorem liftVar_le (h : k ≤ i) : liftVar n i k = n + i := if_neg (Nat.not_lt.2 h)

theorem liftVar_base : liftVar n i = n + i := liftVar_le (Nat.zero_le _)
@[simp] theorem liftVar_base' : liftVar n i = i + n := Nat.add_comm .. ▸ liftVar_le (Nat.zero_le _)

@[simp] theorem liftVar_zero : liftVar n 0 (k+1) = 0 := by simp [liftVar]
@[simp] theorem liftVar_succ : liftVar n (i+1) (k+1) = liftVar n i k + 1 := by
  simp [liftVar, Nat.succ_lt_succ_iff]; split <;> simp [Nat.add_assoc]

theorem liftVar_lt_add (self : i < k) : liftVar n i j < k + n := by
  simp [liftVar]
  split <;> rename_i h
  · exact Nat.lt_of_lt_of_le self (Nat.le_add_right ..)
  · rw [Nat.add_comm]; exact Nat.add_lt_add_right self _

variable (n : Nat) in
mutual
/-- Evaluate `↑ⁿ⁺ᵏ:k` at a type expression. -/
@[semireducible] def TyExpr.liftN : TyExpr → (k : Nat := 0) → TyExpr
  | .univ, _ => .univ
  | .el A, k => .el (A.liftN k)
  | .pi ty body, k => .pi (ty.liftN k) (body.liftN (k+1))

/-- Evaluate `↑ⁿ⁺ᵏ:k` at an expression. -/
@[semireducible] def Expr.liftN : Expr → (k : Nat := 0) → Expr
  | .bvar i, k => .bvar (liftVar n i k)
  | .app fn arg, k => .app (fn.liftN k) (arg.liftN k)
  | .lam ty body, k => .lam (ty.liftN k) (body.liftN (k+1))
  | .pi ty body, k => .pi (ty.liftN k) (body.liftN (k+1))
end

/-- Evaluate `↑¹` at a type expression. -/
abbrev TyExpr.lift := TyExpr.liftN 1
/-- Evaluate `↑¹` at an expression. -/
abbrev Expr.lift := Expr.liftN 1

/-- Evaluate `↑ᵏ.e[↑ᵏ]:k` at a de Bruijn index `i`. -/
def instVar (i : Nat) (e : Expr) (k := 0) : Expr :=
  if i < k then .bvar i else if i = k then .liftN k e else .bvar (i - 1)

mutual
/-- Evaluate `↑ᵏ.e[↑ᵏ]:k` at a type expression. -/
def TyExpr.inst : TyExpr → Expr → (k :_:= 0) → TyExpr
  | .univ, _, _ => .univ
  | .el a, e, k => .el (a.inst e k)
  | .pi ty body, e, k => .pi (ty.inst e k) (body.inst e (k+1))

/-- Evaluate `↑ᵏ.e[↑ᵏ]:k` at an expression. -/
def Expr.inst : Expr → Expr → (k :_:= 0) → Expr
  | .bvar i, e, k => instVar i e k
  | .app fn arg, e, k => .app (fn.inst e k) (arg.inst e k)
  | .lam ty body, e, k => .lam (ty.inst e k) (body.inst e (k+1))
  | .pi ty body, e, k => .pi (ty.inst e k) (body.inst e (k+1))
end

end Substitutions
end RawSyntax

/-! In this section we specify typing judgments of the type theory
as `Prop`-valued relations. -/
section Typing

mutual
inductive HasType : List TyExpr → Expr → TyExpr → Prop
  | weak {e A Γ} : HasType Γ e A → HasType (A :: Γ) e.lift A.lift
  | bvar {A Γ} : HasType (A :: Γ) (.bvar 0) A.lift
  | app {A B f a Γ} : HasType Γ f (.pi A B) → HasType Γ a A → HasType Γ (.app f a) (.inst B a)
  | lam {A B e Γ} : IsType Γ A → HasType (A :: Γ) e B → HasType Γ (.lam A e) (.pi A B)

inductive IsType : List TyExpr → TyExpr → Prop
  -- Note: works in any context, including ill-formed ones,
  -- so we do not have wf-ctx inversion.
  | univ {Γ} : IsType Γ .univ
  | el {A Γ} : HasType Γ A .univ → IsType Γ (.el A)
  | pi {A B Γ} : IsType Γ A → IsType (A :: Γ) B → IsType Γ (.pi A B)
end

end Typing

open CategoryTheory NaturalModel
open Functor Limits Opposite Representable
noncomputable section

variable {Ctx : Type u} [SmallCategory Ctx] [HasTerminal Ctx] [M : NaturalModel Ctx]

def wU : y(Γ) ⟶ M.Ty := yoneda.map (terminal.from Γ) ≫ U

@[simp]
theorem comp_wU (Δ Γ : Ctx) (f : y(Δ) ⟶ y(Γ)) : f ≫ wU = wU := by
  aesop (add norm wU)

/-- `CtxStack Γ` witnesses that the semantic context `Γ`
is built by successive context extension operations. -/
inductive CtxStack : Ctx → Type u where
  | nil : CtxStack (⊤_ Ctx)
  | cons {Γ} (A : y(Γ) ⟶ Ty) : CtxStack Γ → CtxStack (M.ext Γ A)

variable (Ctx) in
def Context : Type u := Σ Γ : Ctx, CtxStack Γ

abbrev Context.ty (Γ : Context Ctx) := y(Γ.1) ⟶ Ty
abbrev Context.tm (Γ : Context Ctx) := y(Γ.1) ⟶ Tm

def Context.typed (Γ : Context Ctx) (A : Γ.ty) := { x : Γ.tm // x ≫ tp = A }

def Context.nil : Context Ctx := ⟨_, .nil⟩

def Context.cons (Γ : Context Ctx) (A : Γ.ty) : Context Ctx := ⟨_, .cons A Γ.2⟩

@[simp] theorem Context.cons_fst (Γ : Context Ctx) (A : Γ.ty) :
    (Γ.cons A).1 = ext Γ.1 A := rfl

def Context.weak (Γ : Context Ctx) (A : Γ.ty)
  {P : Psh Ctx} (f : y(Γ.1) ⟶ P) : y((cons Γ A).1) ⟶ P :=
  yoneda.map (disp Γ.1 A) ≫ f

protected def CtxStack.var {Γ : Ctx} : CtxStack Γ → ℕ → Part (y(Γ) ⟶ Tm)
  | .nil, _ => .none
  | .cons _ _, 0 => pure <| var ..
  | .cons _ S, n+1 => Context.weak ⟨_, S⟩ _ <$> S.var n

protected def Context.var (Γ : Context Ctx) (i : ℕ) : Part Γ.tm := Γ.2.var i

def substCons {Γ Δ : Ctx} (σ : y(Γ) ⟶ y(Δ))
    (e : y(Γ) ⟶ Tm) (A : y(Δ) ⟶ Ty) (eTy : e ≫ tp = σ ≫ A) :
    y(Γ) ⟶ y(ext Δ A) := by
  refine yoneda.map <| Yoneda.fullyFaithful.1 <| (disp_pullback A).isLimit.lift <|
    PullbackCone.mk e σ ?_
  ext; simp [← eTy]

@[reassoc (attr := simp)] theorem substCons_var {Γ Δ : Ctx} (σ : y(Γ) ⟶ y(Δ))
    (e : y(Γ) ⟶ Tm) (A : y(Δ) ⟶ Ty) (eTy : e ≫ tp = σ ≫ A) :
    substCons σ e A eTy ≫ var _ _ = e := by
  simpa [substCons] using (disp_pullback A).isLimit.fac _ (some .left)

@[reassoc (attr := simp)] theorem substCons_disp {Γ Δ : Ctx} (σ : y(Γ) ⟶ y(Δ))
    (e : y(Γ) ⟶ Tm) (A : y(Δ) ⟶ Ty) (eTy : e ≫ tp = σ ≫ A) :
    substCons σ e A eTy ≫ yoneda.map (disp _ _) = σ := by
  simpa [substCons] using (disp_pullback A).isLimit.fac _ (some .right)

def substFst {Γ Δ : Ctx} {A : y(Δ) ⟶ Ty} (σ : y(Γ) ⟶ y(ext Δ A)) : y(Γ) ⟶ y(Δ) :=
  σ ≫ yoneda.map (disp _ _)

def substSnd {Γ Δ : Ctx} {A : y(Δ) ⟶ Ty} (σ : y(Γ) ⟶ y(ext Δ A)) : y(Γ) ⟶ Tm := σ ≫ var _ _

theorem substSnd_ty {Γ Δ : Ctx} {A : y(Δ) ⟶ Ty} (σ : y(Γ) ⟶ y(ext Δ A)) :
    substSnd σ ≫ tp = substFst σ ≫ A := by
  simp [substSnd, substFst]; rw [(disp_pullback _).w]

def weakSubst {Δ Γ : Ctx} (f : y(Δ) ⟶ y(Γ)) (A : y(Γ) ⟶ Ty) : y(ext Δ (f ≫ A)) ⟶ y(ext Γ A) :=
  substCons (yoneda.map (disp ..) ≫ f) (var ..) _ (by simpa using (disp_pullback (f ≫ A)).w)

def mkEl {Γ : Context Ctx} (A : Γ.typed wU) : Γ.ty :=
  substCons (yoneda.map $ terminal.from _) A.1 _ A.2 ≫ El

def mkP_equiv {Γ : Ctx} {X : Psh Ctx} :
    (y(Γ) ⟶ (P tp).obj X) ≃ (A : y(Γ) ⟶ Ty) × (y(ext Γ A) ⟶ X) :=
  ((uvPoly tp).equiv' y(Γ) X).trans <|
  Equiv.sigmaCongrRight fun A =>
  ((yoneda.obj X).mapIso (disp_pullback A).isoPullback.op).toEquiv

def mkP {Γ : Ctx} {X : Psh Ctx} (A : y(Γ) ⟶ Ty) (B : y(ext Γ A) ⟶ X) :
    y(Γ) ⟶ (P tp).obj X := mkP_equiv.2 ⟨A, B⟩

theorem mkP_app {Γ : Ctx} {X Y : Psh Ctx} (A : y(Γ) ⟶ Ty)
    (F : X ⟶ Y) (B : y(ext Γ A) ⟶ X) :
    mkP A B ≫ (P tp).map F = mkP A (B ≫ F) := by
  sorry

theorem comp_mkP {Δ Γ : Ctx} (f : y(Δ) ⟶ y(Γ)) (A : y(Γ) ⟶ Ty) (B : y(ext Γ A) ⟶ X) :
    f ≫ mkP A B = mkP (f ≫ A) (weakSubst f A ≫ B) := by
  sorry

def mkPi {Γ : Context Ctx} (A : Γ.ty) (B : (Γ.cons A).ty) : Γ.ty :=
  mkP A B ≫ NaturalModelPi.Pi

theorem comp_mkPi {Γ Δ : Context Ctx} (f : y(Δ.1) ⟶ y(Γ.1)) (A : Γ.ty) (B : (Γ.cons A).ty) :
    f ≫ mkPi A B = mkPi (f ≫ A) (weakSubst f A ≫ B) := by simp [mkPi, ← comp_mkP]

def mkLam' {Γ : Context Ctx} (A : Γ.ty) (e : (Γ.cons A).tm) : Γ.tm :=
  mkP A e ≫ NaturalModelPi.lam

theorem comp_mkLam' {Γ Δ : Context Ctx} (f : y(Δ.1) ⟶ y(Γ.1)) (A : Γ.ty) (B : (Γ.cons A).tm) :
    f ≫ mkLam' A B = mkLam' (f ≫ A) (weakSubst f A ≫ B) := by simp [mkLam', ← comp_mkP]

def Context.subst {Γ : Context Ctx} {X : Psh Ctx}
    (A : Γ.ty) (B : y((Γ.cons A).1) ⟶ X) (a : Γ.typed A) : y(Γ.1) ⟶ X :=
  substCons (𝟙 _) a.1 A (by simpa using a.2) ≫ B

def mkTyped {Γ Δ : Context Ctx} {A : Δ.ty} (σ : y(Γ.1) ⟶ y(ext Δ.1 A))
    {Aσ} (eq : substFst σ ≫ A = Aσ) :
    Γ.typed Aσ := ⟨substSnd _, eq ▸ substSnd_ty _⟩

def mkLam {Γ : Context Ctx} (A : Γ.ty) (B : (Γ.cons A).ty) (e : (Γ.cons A).typed B) :
    Γ.typed (mkPi A B) := by
  refine ⟨mkLam' A e.1, ?_⟩
  simp [mkLam', mkPi, NaturalModelPi.Pi_pullback.w]
  rw [← Category.assoc, mkP_app, e.2]

def mkPApp {Γ : Context Ctx} (A : Γ.ty) (B : (Γ.cons A).ty)
    (f : Γ.typed (mkPi A B)) : (Γ.cons A).typed B := by
  let total' : y(Γ.1) ⟶ (P tp).obj Tm :=
    NaturalModelPi.Pi_pullback.isLimit.lift <|
    PullbackCone.mk f.1 (mkP A B) f.2
  have : total' ≫ (P tp).map tp = mkP A B :=
    NaturalModelPi.Pi_pullback.isLimit.fac _ (some .right)
  let total := mkP_equiv.1 total'
  have := mkP_equiv.symm.injective <|
    show mkP total.1 (total.2 ≫ tp) = mkP A B by
      rw [← mkP_app]; simp [mkP, total, this]
  have aeq : total.1 = A := congrArg Sigma.fst this
  refine ⟨aeq ▸ total.2, ?_⟩
  clear_value total'; cases this; rfl

def mkApp {Γ : Context Ctx} (A : Γ.ty) (B : (Γ.cons A).ty)
    (f : Γ.typed (mkPi A B)) (a : Γ.typed A) : Γ.typed (Γ.subst A B a) := by
  refine ⟨Γ.subst A (mkPApp A B f).1 a, ?_⟩
  simp [Context.subst]
  congr! 1; exact (mkPApp A B f).2

def mkSmallPi {Γ : Context Ctx} (A : Γ.typed wU) (B : (Γ.cons (mkEl A)).typed wU) : Γ.typed wU := by
  refine mkTyped (Δ := .nil) (?a ≫ NaturalModelSmallPi.SmallPi (Ctx := Ctx)) ?b
  case b =>
    simp only [Context.nil, Psh, wU, substFst]; congr
    apply Yoneda.fullyFaithful.homEquiv.symm.injective; ext
  refine ((uvPoly _).equiv' _ _).2 ⟨?_, ?_⟩
  · exact substCons (yoneda.map $ terminal.from _) A.1 _ A.2
  · refine ?_ ≫ substCons (yoneda.map $ terminal.from _) B.1 _ B.2
    dsimp [uvPoly]
    refine (disp_pullback (Ctx := Ctx) _).isLimit.lift <|
      PullbackCone.mk (pullback.fst ≫ var _ _) pullback.snd ?_
    rw [mkEl, Category.assoc, (disp_pullback _).w, ← Category.assoc,
      pullback.condition, Category.assoc]

mutual

def ofType (Γ : Context Ctx) : TyExpr → Part Γ.ty
  | .univ => pure wU
  | .pi A B => do
    let A ← ofType Γ A
    let B ← ofType (Γ.cons A) B
    pure (mkPi A B)
  | .el e => do
    let v ← ofTerm Γ e
    Part.assert _ fun h => pure <| mkEl ⟨v, h⟩

def ofTerm (Γ : Context Ctx) : Expr → Part Γ.tm
  | .bvar i => Context.var _ i
  -- | .univ => .none
  | .pi A B => do
    let A ← ofTerm Γ A
    Part.assert (A ≫ tp = wU) fun hA => do
    let B ← ofTerm (Γ.cons (mkEl ⟨A, hA⟩)) B
    Part.assert (B ≫ tp = wU) fun hB => do
    pure (mkSmallPi ⟨A, hA⟩ ⟨B, hB⟩).1
  | .lam A e => do
    let A ← ofType Γ A
    let e ← ofTerm (Γ.cons A) e
    pure (mkLam A _ ⟨e, rfl⟩).1
  | .app f a => do
    let f ← ofTerm Γ f
    let a ← ofTerm Γ a
    Part.assert (∃ B, f ≫ tp = mkPi (a ≫ tp) B) fun h =>
    pure (mkApp _ h.choose ⟨f, h.choose_spec⟩ ⟨a, rfl⟩).1

end

def ofCtx : List TyExpr → Part (Context Ctx)
  | [] => pure .nil
  | A :: Γ => do let Γ ← ofCtx Γ; Γ.cons (← ofType Γ A)

theorem ofTerm_app (Γ : Context Ctx) {f a e'} :
    e' ∈ ofTerm Γ (.app f a) ↔ ∃ f' ∈ ofTerm Γ f, ∃ a' ∈ ofTerm Γ a, ∃ t', ∃ ht' : a' ≫ tp = t',
      ∃ B, ∃ hB : f' ≫ tp = mkPi t' B, e' = (mkApp _ B ⟨f', hB⟩ ⟨a', ht'⟩).1 := by
  simp [ofTerm]
  refine exists_congr fun f' => and_congr_right fun hf => ?_
  refine exists_congr fun a' => and_congr_right fun ha => ?_
  refine ⟨fun ⟨⟨B, hB⟩, H⟩ => ⟨_, rfl, _, _, H⟩,
    fun ⟨_, rfl, B, hB, H⟩ => have h := ⟨B, hB⟩; ⟨h, ?_⟩⟩
  suffices ∀ B', f' ≫ tp = mkPi (a' ≫ tp) B' → B = B' by
    specialize this h.choose h.choose_spec
    subst B; exact H
  intro B' hB'
  simp [hB, mkPi] at hB'
  sorry

-- mutual

-- theorem ofTerm_lift (h : e' ∈ ofTerm Γ (.liftN e k)) : e' ∈ ofTerm Γ (.liftN e k) := sorry
-- end

@[simp] def CtxStack.size {Γ : Ctx} : CtxStack Γ → Nat
  | .nil => 0
  | .cons _ S => S.size + 1

@[simp] def CtxStack.dropN {Γ : Ctx} : ∀ k (S : CtxStack Γ), k ≤ S.size → Context Ctx
  | 0, S, _ => ⟨Γ, S⟩
  | _+1, .cons .., h => CtxStack.dropN _ _ (Nat.le_of_succ_le_succ h)

@[simp] def CtxStack.dropN_disp {Γ : Ctx} :
    ∀ (k : Nat) (S : CtxStack Γ) (h : k ≤ S.size), Γ ⟶ (S.dropN k h).1
  | 0, _, _ => 𝟙 _
  | _+1, .cons .., h => disp .. ≫ CtxStack.dropN_disp _ _ (Nat.le_of_succ_le_succ h)

@[simp] def CtxStack.extN {Γ : Ctx} : ∀ {k : Nat} {S : CtxStack Γ} {h : k ≤ S.size},
    (S.dropN k h).ty → Σ Δ : Context Ctx, y(Δ.1) ⟶ y(Γ)
  | 0, _, _, X => ⟨.cons _ X, yoneda.map (disp ..)⟩
  | _+1, .cons A _, h, X =>
    let ⟨Δ, wk⟩ := CtxStack.extN (h := Nat.le_of_succ_le_succ h) X
    ⟨.cons Δ (wk ≫ A), weakSubst ..⟩

def Context.tyN (Γ : Context Ctx) (k : Nat) : Type u := Σ' h : k ≤ Γ.2.size, (Γ.2.dropN k h).ty

def Context.tyN.up {Γ : Context Ctx} {k : Nat} {A} : Γ.tyN k → (Γ.cons A).tyN (k+1)
  | ⟨h, X⟩ => ⟨Nat.succ_le_succ h, X⟩

def Context.tyN.down {Γ : Context Ctx} {k : Nat} {A} : (Γ.cons A).tyN (k+1) → Γ.tyN k
  | ⟨h, X⟩ => ⟨Nat.le_of_succ_le_succ h, X⟩

def Context.consN (Γ : Context Ctx) (A : Γ.tyN k) : Context Ctx := (Γ.2.extN A.2).1

def Context.dispN (Γ : Context Ctx) (A : Γ.tyN k) : y((consN Γ A).1) ⟶ y(Γ.1) := (Γ.2.extN A.2).2

def Context.weakN (Γ : Context Ctx) (A : Γ.tyN k)
  {P : Psh Ctx} (f : y(Γ.1) ⟶ P) : y((consN Γ A).1) ⟶ P := dispN Γ A ≫ f

mutual

theorem ofType_liftN {k : Nat} {Γ : Context Ctx} :
  ∀ {A A'} (X : Γ.tyN k), A' ∈ ofType Γ A → Context.weakN Γ X A' ∈ ofType (Γ.consN X) (A.liftN 1 k)
  | .univ, _, _, H => by
    simp [ofType] at H; subst H; simp [TyExpr.liftN, ofType]; apply comp_wU
  | .pi A B, _, X, H => by
    simp [ofType] at H
    obtain ⟨A', hA, B', hB, rfl⟩ := H
    simp [TyExpr.liftN, ofType]
    refine ⟨_, ofType_liftN X hA, _, ofType_liftN X.up hB, ?_⟩
    apply comp_mkPi
  | .el A, _, X, H => by
    simp [ofType] at H
    obtain ⟨A', hA, ha, rfl⟩ := H
    simp [TyExpr.liftN, ofType, ofTerm]
    refine ⟨_, ofTerm_liftN X hA, by simp [Context.weakN, ha], ?_⟩
    simp only [Context.weakN, mkEl, ← Category.assoc]; congr 1
    sorry

theorem ofTerm_liftN {k : Nat} {Γ : Context Ctx} : ∀ {e e'} (X : Γ.tyN k),
    e' ∈ ofTerm Γ e → Context.weakN Γ X e' ∈ ofTerm (Γ.consN X) (e.liftN 1 k)
  | .bvar n, e', ⟨hX, X⟩, H => by
    let ⟨Γ, S⟩ := Γ
    simp only [Expr.liftN, ofTerm, Context.var, Context.consN, Context.weakN, Context.dispN] at H ⊢
    dsimp [Context.tm] at X hX e'
    induction k generalizing n Γ with
    | zero =>
      simp [Context.cons, CtxStack.var]
      exact ⟨_, H, rfl⟩
    | succ k ih =>
      obtain _ | ⟨A, S⟩ := S; · nomatch hX
      cases n with simp [CtxStack.var] at H
      | zero => subst e'; simp [CtxStack.var, weakSubst]
      | succ n =>
        obtain ⟨e, he, rfl⟩ := H
        simp [CtxStack.var]
        refine ⟨_, ih n _ S e (Nat.le_of_succ_le_succ hX) X he, ?_⟩
        simp [Context.weak, weakSubst]
  | .app f a, _, X, H => by
    simp [Expr.liftN, ofTerm_app] at H ⊢
    obtain ⟨f', hf, a', ha, _, rfl, B, hB, rfl⟩ := H
    refine ⟨_, ofTerm_liftN X hf, _, ofTerm_liftN X ha, ?_⟩
    refine ⟨Γ.weakN X (a' ≫ tp), ?_, Context.weakN _ X.up B, ?_, ?_⟩
    · simp [Context.weakN]
    · simp [Context.weakN, hB, comp_mkPi]; rfl
    · sorry
  | .lam ty val, _, _, H => sorry
  | .pi A B, _, _, H => sorry

end

theorem ofType_lift {Γ : Context Ctx} {A A'} (X : Γ.ty) (H : A' ∈ ofType Γ A) :
    Context.weak Γ X A' ∈ ofType (Γ.cons X) A.lift := ofType_liftN ⟨Nat.zero_le _, X⟩ H

theorem ofTerm_lift {Γ : Context Ctx} {e e'} (X : Γ.ty) (H : e' ∈ ofTerm Γ e) :
    Context.weak Γ X e' ∈ ofTerm (Γ.cons X) e.lift := ofTerm_liftN ⟨Nat.zero_le _, X⟩ H

theorem ofTerm_ofType_correct :
    (∀ {Γ e A} (H : HasType Γ e A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ),
      ∃ A' ∈ ofType Γ' A, ∃ e' ∈ ofTerm Γ' e, e' ≫ tp = A') ∧
    (∀ {Γ A} (H : IsType Γ A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ),
      (ofType Γ' A).Dom) := by
  let ofTerm_correct Γ e A := ∀ {Γ'}, Γ' ∈ ofCtx (Ctx := Ctx) Γ →
      ∃ A' ∈ ofType Γ' A, ∃ e' ∈ ofTerm Γ' e, e' ≫ tp = A'
  let ofType_correct Γ A := ∀ {Γ'}, Γ' ∈ ofCtx (Ctx := Ctx) Γ → (ofType Γ' A).Dom
  refine
    ⟨@HasType.rec (fun Γ e A _ => ofTerm_correct Γ e A) (fun Γ A _ => ofType_correct Γ A)
      ?weak ?bvar ?app ?lam ?univ ?el ?pi,
     @IsType.rec (fun Γ e A _ => ofTerm_correct Γ e A) (fun Γ A _ => ofType_correct Γ A)
      ?weak ?bvar ?app ?lam ?univ ?el ?pi⟩
  case bvar =>
    intro A Γ Γ' hΓ
    simp [ofCtx] at hΓ
    obtain ⟨Γ', hΓ', A', hA, rfl⟩ := hΓ
    refine ⟨_, ofType_lift A' hA, _, by rw [ofTerm]; apply Part.mem_some, ?_⟩
    rw [(disp_pullback A').w]; rfl
  case weak =>
    intro e A Γ he ihe Γ' hΓ
    simp [ofCtx] at hΓ
    obtain ⟨Γ', hΓ, A', hA, rfl⟩ := hΓ
    obtain ⟨_, hA', e', he', rfl⟩ := ihe hΓ
    cases Part.mem_unique hA hA'
    refine ⟨_, ofType_lift _ hA, _, ofTerm_lift _ he', by simp [Context.weak]⟩
  case app =>
    intro A B f a Γ hf ha ihf iha Γ' hΓ
    sorry
  case lam =>
    intro A B e Γ hA he ihA ihe Γ' hΓ
    have ⟨A', hA⟩ := Part.dom_iff_mem.1 (ihA hΓ)
    obtain ⟨_, hB, e', he, rfl⟩ := ihe (by simpa [ofCtx] using ⟨_, hΓ, _, hA, rfl⟩)
    simp [ofType, ofTerm]
    exact ⟨_, ⟨_, hA, _, hB, rfl⟩, _, ⟨_, hA, _, he, rfl⟩, (mkLam ..).2⟩
  case el =>
    intro A Γ hA ihA Γ' hΓ
    simp [ofType, Part.assert]
    have := ihA hΓ; simp [ofType] at this
    have ⟨_, ⟨h, rfl⟩, eq⟩ := this
    exact ⟨h, eq⟩
  case pi =>
    intro A B Γ hA hB ihA ihB Γ' hΓ
    simp [ofType]
    refine ⟨ihA hΓ, ihB ?_⟩; simp [ofCtx]
    exact ⟨_, hΓ, _, Part.get_mem _, rfl⟩
  case univ => intro Γ Γ' hΓ; simp [ofType]

theorem ofTerm_correct {Γ e A} (H : HasType Γ e A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ) :
    ∃ A' ∈ ofType Γ' A, ∃ e' ∈ ofTerm Γ' e, e' ≫ tp = A' := ofTerm_ofType_correct.1 H hΓ

theorem ofTerm_correct_ty {Γ e A} (H : HasType Γ e A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ) :
    (ofType Γ' A).Dom :=
  let ⟨_, ⟨h, rfl⟩, _⟩ := ofTerm_correct H hΓ
  h

theorem ofTerm_correct_tm {Γ e A} (H : HasType Γ e A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ) :
    (ofTerm Γ' e).Dom :=
  let ⟨_, _, _, ⟨h, rfl⟩, _⟩ := ofTerm_correct H hΓ
  h

theorem ofTerm_correct_tp {Γ A} (H : HasType Γ e A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ) :
    (ofTerm Γ' e).get (ofTerm_correct_tm H hΓ) ≫ tp =
    (ofType Γ' A).get (ofTerm_correct_ty H hΓ) :=
  let ⟨_, ⟨_, rfl⟩, _, ⟨_, rfl⟩, eq⟩ := ofTerm_correct H hΓ
  eq

theorem ofType_correct {Γ A} (H : IsType Γ A) {Γ'} (hΓ : Γ' ∈ ofCtx (Ctx := Ctx) Γ) :
    (ofType Γ' A).Dom := ofTerm_ofType_correct.2 H hΓ

section Examples

def Typed (Γ A) := { e // HasType Γ e A }

def foo._hott : Typed [] (TyExpr.pi .univ .univ) := ⟨Expr.lam .univ (.bvar 0), .lam .univ .bvar⟩

-- example : HasType [] (Expr.lam .univ (.bvar 0)) (TyExpr.pi .univ .univ) :=
--   .lam .univ .bvar

def toModelType {A} (e : Typed [] A) : y(⊤_ _) ⟶ M.Ty :=
  (ofType .nil A).get (ofTerm_correct_ty (Ctx := Ctx) e.2 ⟨trivial, rfl⟩)

def toModel {A} (e : Typed [] A) : y(⊤_ _) ⟶ M.Tm :=
  (ofTerm .nil e.1).get (ofTerm_correct_tm (Ctx := Ctx) e.2 ⟨trivial, rfl⟩)

theorem toModel_type {A} (e : Typed [] A) : toModel e ≫ tp = toModelType (Ctx := Ctx) e :=
  ofTerm_correct_tp (Ctx := Ctx) e.2 ⟨trivial, rfl⟩

example : y(⊤_ _) ⟶ M.Tm := toModel foo._hott

end Examples
