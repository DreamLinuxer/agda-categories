{-# OPTIONS --without-K --safe #-}

module Categories.Category.Construction.Quivers where

-- The "Underlying Graph" <-> "Free Category on a Graph" Adjunction.
--   [It's actually a Multidigraph, or Quiver.  Use the latter.]
-- Lots of surprises here, of various level of surprisingness
-- 1. The Free Category rises universe levels of arrows (and equivalences); the Underlying Graph does not
--   (due to the Transitive Closure "Star" construction)
-- 2. As a consequence of (1), the eventual Adjunction will be for all Levels being the same
-- 3. If you want a Functor Categories Graph, then the object/hom levels are straightforward,
--   but if you use "Categories" with NaturalIsomorphism, then the 2-point Groupoid is contractible
--   (thus equivalent to the 1-point Category), and yet those two Graphs shouldn't be considered to
--   be the same!  So _≡F_ must be used so that we have no wiggle room when mapping Graphs around.
--   Interestingly, this only shows up when trying to prove that the Underlying Functor respects
--   _≈_, which is not traditionally a requirement of a Functor! This requirement is usually left
--   implicit.  If we were to allow Functor to not respect _≈_, things would be fine. But of course
--   we couldn't do any reasonable equational reasoning anymore.  Of course, if _≈_ were the global
--   _≡_, this isn't an issue, but that is definitely not wanted here.
-- 4. A lot of weird little lemmas about _≡_ and subst/transport are needed, because we're in a mixed
--   reasoning situation with both ≡ and ≈ present.  These could probably be generalized and factored
--   into a separate module (or into the standard library).

open import Level
open import Function using (_$_; flip)
open import Relation.Binary.PropositionalEquality as ≡
open import Relation.Binary.PropositionalEquality.Subst.Properties
open import Relation.Binary.Construct.Closure.ReflexiveTransitive
open import Relation.Binary.Construct.Closure.ReflexiveTransitive.Properties hiding (trans)
open import Data.Quiver
open import Data.Quiver.Paths
import Data.Quiver.Morphism as QM
open QM using (Morphism; _≃_)

open import Categories.Category
import Categories.Category.Construction.FreeQuiver as FQ
open import Categories.Category.Instance.StrictCats
open import Categories.Functor using (Functor)
open import Categories.Functor.Equivalence using (_≡F_)
open import Categories.NaturalTransformation hiding (id)
open import Categories.NaturalTransformation.NaturalIsomorphism
  hiding (refl; sym; trans; isEquivalence; _≃_)
import Categories.Morphism.HeterogeneousIdentity as HId

private
  variable
    o o′ ℓ ℓ′ e e′ : Level

-- The Category of Quivers
Quivers : ∀ o ℓ e → Category (suc (o ⊔ ℓ ⊔ e)) (o ⊔ ℓ ⊔ e) (o ⊔ ℓ ⊔ e)
Quivers o ℓ e = record
  { Obj       = Quiver o ℓ e
  ; _⇒_       = Morphism
  ; _≈_       = _≃_
  ; id        = QM.id
  ; _∘_       = QM._∘_
  ; assoc     = λ {_ _ _ G} → record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
  ; sym-assoc = λ {_ _ _ G} → record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
  ; identityˡ = λ {_ G}     → record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
  ; identityʳ = λ {_ G}     → record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
  ; identity² = λ {G}       → record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
  ; equiv     = λ {_ G} → record
    { refl  = record { F₀≡ = refl ; F₁≡ = Equiv.refl G }
    ; sym   = λ {i j} eq → record
      { F₀≡ = sym (F₀≡ eq)
      ; F₁≡ = λ {_ _ f} →
        let open EdgeReasoning G
            open Transport (_⇒_ G)
            open TransportOverQ (_⇒_ G) (_≈_ G)
            e₁ = F₀≡ eq
        in begin
          F₁ j f ▸ sym e₁                        ≡˘⟨ cong (_◂ (F₁ j f ▸ _)) (trans-symˡ e₁) ⟩
          trans (sym e₁) e₁ ◂ (F₁ j f ▸ sym e₁)  ≡˘⟨ ◂-assocˡ (sym e₁) (F₁ j f ▸ sym e₁) ⟩
          sym e₁ ◂ e₁ ◂ (F₁ j f ▸ sym e₁)        ≡⟨ cong (sym e₁ ◂_) (◂-▸-comm e₁ (F₁ j f) (sym e₁)) ⟩
          sym e₁ ◂ ((e₁ ◂ F₁ j f) ▸ sym e₁)      ≈˘⟨ ◂-resp-≈ (sym e₁) (▸-resp-≈ (F₁≡ eq) (sym e₁)) ⟩
          sym e₁ ◂ (F₁ i f ▸ e₁ ▸ sym e₁)        ≡⟨ cong (sym e₁ ◂_) (▸-assocʳ (F₁ i f) (sym e₁)) ⟩
          sym e₁ ◂ (F₁ i f ▸ trans e₁ (sym e₁))  ≡⟨ cong (λ p → sym e₁ ◂ (F₁ i f ▸ p)) (trans-symʳ e₁) ⟩
          sym e₁ ◂ F₁ i f                        ∎
      }
    ; trans = λ {i j k} eq eq′ → record
      { F₀≡ = trans (F₀≡ eq) (F₀≡ eq′)
      ; F₁≡ = λ {_ _ f} →
        let open EdgeReasoning G
            open Transport (_⇒_ G)
            open TransportOverQ (_⇒_ G) (_≈_ G)
        in begin
          F₁ i f ▸ trans (F₀≡ eq) (F₀≡ eq′)  ≡˘⟨ ▸-assocʳ (F₁ i f) (F₀≡ eq′) ⟩
          (F₁ i f ▸ F₀≡ eq) ▸ F₀≡ eq′        ≈⟨ ▸-resp-≈ (F₁≡ eq) (F₀≡ eq′) ⟩
          (F₀≡ eq ◂ F₁ j f) ▸ F₀≡ eq′        ≡˘⟨ ◂-▸-comm (F₀≡ eq) (F₁ j f) (F₀≡ eq′) ⟩
          F₀≡ eq ◂ (F₁ j f ▸ F₀≡ eq′)        ≈⟨ ◂-resp-≈ (F₀≡ eq) (F₁≡ eq′) ⟩
          F₀≡ eq ◂ (F₀≡ eq′ ◂ F₁ k f)        ≡⟨ ◂-assocˡ (F₀≡ eq) (F₁ k f) ⟩
          trans (F₀≡ eq) (F₀≡ eq′) ◂ F₁ k f  ∎
      }
    }
  ; ∘-resp-≈  = λ {_ G H} {f g h i} eq eq′ → record
    { F₀≡ = trans (cong (F₀ f) (F₀≡ eq′)) (F₀≡ eq)
    ; F₁≡ = λ {_ _ j} →
      let open EdgeReasoning H
          open Transport (_⇒_ H)
          open TransportOverQ (_⇒_ H) (_≈_ H)
          open Transport (_⇒_ G) using () renaming (_▸_ to _▹_; _◂_ to _◃_)
          open TransportMor (_⇒_ G) (_⇒_ H)
          e₁ = F₀≡ eq
          e₂ = F₀≡ eq′
      in begin
        F₁ (f QM.∘ h) j ▸ trans (cong (F₀ f) e₂) e₁ ≡˘⟨ ▸-assocʳ (F₁ f (F₁ h j)) e₁ ⟩
        F₁ f (F₁ h j) ▸ cong (F₀ f) e₂ ▸ e₁         ≡˘⟨ cong (_▸ e₁) ( M-resp-▸ (F₀ f) (F₁ f) (F₁ h j) e₂) ⟩
        F₁ f (F₁ h j ▹ e₂) ▸ e₁                     ≈⟨ F₁≡ eq ⟩
        e₁ ◂ F₁ g (F₁ h j ▹ e₂)                     ≈⟨ ◂-resp-≈ e₁ (F-resp-≈ g (F₁≡ eq′)) ⟩
        e₁ ◂ F₁ g (e₂ ◃ F₁ i j)                     ≡⟨ cong (e₁ ◂_) (M-resp-◂ (F₀ g) (F₁ g) e₂ (F₁ i j) ) ⟩
        e₁ ◂ cong (F₀ g) e₂ ◂ F₁ g (F₁ i j)         ≡⟨ ◂-assocˡ e₁ (F₁ g (F₁ i j)) ⟩
        trans e₁ (cong (F₀ g) e₂) ◂ F₁ g (F₁ i j)   ≡˘⟨ cong (_◂ F₁ g (F₁ i j)) (naturality (λ _ → e₁)) ⟩
        trans (cong (F₀ f) e₂) e₁ ◂ F₁ g (F₁ i j)   ∎
    }
  }
  where
    open Quiver
    open Morphism
    open _≃_

-- We can now build a forgetful (underlying) functor from categories to quivers
Underlying₀ : Category o ℓ e → Quiver o ℓ e
Underlying₀ C = record { Category C }

Underlying₁ : {C : Category o ℓ e} {D : Category o′ ℓ′ e′} → Functor C D → Morphism (Underlying₀ C) (Underlying₀ D)
Underlying₁ F = record { Functor F }

Underlying : Functor (Cats o ℓ e) (Quivers o ℓ e)
Underlying = record
  { F₀ = Underlying₀
  ; F₁ = Underlying₁
  ; identity = λ {A} → record { F₀≡ = refl ; F₁≡ = Category.Equiv.refl A }
  ; homomorphism = λ where {Z = Z} → record { F₀≡ = refl ; F₁≡ = Category.Equiv.refl Z }
  ; F-resp-≈ = λ {A} {B} {F} {G} F≈G → record
    { F₀≡ = λ {X} → eq₀ F≈G X
    ; F₁≡ = λ {x} {y} {f} →
      let open Category B
          open HId B
          UB = Underlying₀ B
          open Transport (Quiver._⇒_ UB)
          open Functor
          open Quiver.EdgeReasoning (Underlying₀ B)
      in begin
        F₁ F f ▸ eq₀ F≈G y         ≈⟨ hid-subst-cod (F₁ F f) (eq₀ F≈G y) ⟩
        hid (eq₀ F≈G y) ∘ F₁ F f   ≈⟨ eq₁ F≈G f ⟩
        F₁ G f ∘ hid (eq₀ F≈G x)   ≈˘⟨ hid-subst-dom (eq₀ F≈G x) (F₁ G f) ⟩
        eq₀ F≈G x ◂ F₁ G f         ∎
    }
  }
  where
  open NaturalTransformation
  open NaturalIsomorphism
  open _≡F_

-- define these ahead of time
module _ {G₁ G₂ : Quiver o ℓ e} (G⇒ : Morphism G₁ G₂) where
  open Quiver G₁ renaming (_⇒_ to _⇒₁_; Obj to Obj₁)
  open Quiver G₂ renaming (_⇒_ to _⇒₂_; Obj to Obj₂; module Equiv to Equiv₂)
  open FQ
  open Morphism G⇒

  qmap : {A B : Obj₁} → Star _⇒₁_ A B → Star _⇒₂_ (F₀ A) (F₀ B)
  qmap = gmap F₀ F₁

  -- this is needed, because this uses F-resp-≈ and not ≡
  -- unlike gmap-cong
  map-resp : {A B : Obj₁} (f : Star _⇒₁_ A B) {g : Star _⇒₁_ A B} →
      [ G₁ ] f ≈* g → [ G₂ ] qmap f ≈* qmap g
  map-resp ε ε = ε
  map-resp (x ◅ f) (f≈* ◅ eq) = F-resp-≈ f≈* ◅ map-resp f eq

module _ {G H : Quiver o ℓ e} {f g : Morphism G H}
         (f≈g : f ≃ g) where
  open Quiver G
  open Paths H
  open Morphism
  open _≃_ f≈g
  open Transport (Quiver._⇒_ H)
  open TransportStar (Quiver._⇒_ H)

  map-F₁≡ : {A B : Obj} (hs : Star _⇒_ A B) →
            FQ.[ H ] qmap f hs ▸* F₀≡ ≈* F₀≡ ◂* qmap g hs
  map-F₁≡ ε        = FQ.≡⇒≈* H (◂*-▸*-ε F₀≡)
  map-F₁≡ (hs ◅ h) = begin
    (F₁ f hs ◅ qmap f h) ▸* F₀≡   ≡⟨ ◅-▸* (F₁ f hs) _ F₀≡ ⟩
    F₁ f hs ◅ (qmap f h ▸* F₀≡)   ≈⟨ Quiver.Equiv.refl H ◅ map-F₁≡ h ⟩
    F₁ f hs ◅ (F₀≡ ◂* qmap g h)   ≡⟨ ◅-◂*-▸ (F₁ f hs) F₀≡ _ ⟩
    (F₁ f hs ▸ F₀≡) ◅ qmap g h    ≈⟨ F₁≡ ◅ (Paths.refl H) ⟩
    (F₀≡ ◂ F₁ g hs) ◅ qmap g h    ≡˘⟨ ◂*-◅ F₀≡ (F₁ g hs) _ ⟩
    F₀≡ ◂* (F₁ g hs ◅ qmap g h)   ∎
    where open Paths.PathEqualityReasoning H
