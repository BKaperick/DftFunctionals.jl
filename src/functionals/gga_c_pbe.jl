"""PBE correlation."""
struct PbeCorrelation{Tlda,Tb,Tg} <: Functional{:gga, :c} where {Tlda,Tb,Tg}
    identifier::Symbol
    lda::Tlda
    β::Tb
    γ::Tg
    μ::Tb  # Not used, only stored for convenience
end
function PbeCorrelation(identifier=:gga_c_pbe_custom;
                        lda=DftFunctional{:lda_c_pw}(), β, γ)
    μ = β/3 * π^2
    PbeCorrelation(identifier, lda, β, γ, μ)
end
identifier(pbe::PbeCorrelation) = pbe.identifier


function energy(pbe::PbeCorrelation, ρ::T, σ::U) where {T <: Number, U <: Number}
    β = pbe.β
    γ = pbe.γ

    # Spin-scaling factor with ζ spin polarization.
    # Yue Wang and John P. Perdew. Phys. Rev. B 43, 8911 (1991).
    # DOI 10.1103/PhysRevB.43.8911
    ϕ(ζ) = ((1+ζ)^(2/3) + (1-ζ)^(2/3))/2  # == 1 for non-spin-polarised

    # ε = UEG correlation energy per particle
    A(ε, ϕ³) = β/γ / expm1(-ε / (γ * ϕ³))  # (8)
    function H(ε, t², ϕ³)  # (7)
        At² = A(ε, ϕ³) * t²
        γ * ϕ³ * log(1 + β/γ * t² * (1 + At²) / (1 + At² + (At²)^2))
    end

    phi = #= ϕ(ζ) =# 1.0
    ε_lda = energy_per_particle(pbe.lda, ρ)
    t² = (1/12 * 3^(5/6) * π^(1/6))^2 * σ / (phi^2 * ρ^(7/3))  # page 2, left column, top
    (ε_lda + H(ε_lda, t², phi^3)) * ρ
end


#
# Concrete functionals
#

# TODO Issues with the docstrings ...
# """
# Standard PBE correlation.
# Perdew, Burke, Ernzerhof 1996 (DOI: 10.1103/PhysRevLett.77.3865)
# """
function DftFunctional{:gga_c_pbe}()
    β = 0.06672455060314922
    γ = (1 - log(2)) / π^2
    PbeCorrelation(:gga_c_pbe; β, γ)
end

# """
# XPBE correlation.
# Xu, Goddard 2004 (DOI 10.1063/1.1771632)
# """
function DftFunctional{:gga_c_xpbe}()
    β = 0.089809  # Fitted constants, Table I
    α = 0.197363  # Fitted constants, Table I
    γ = β^2 / 2α
    PbeCorrelation(:gga_c_xpbe; β, γ)
end

# """
# PBESol correlation.
# Perdew, Ruzsinszky, Csonka and others 2008 (DOI 10.1103/physrevlett.100.136406)
# """
function DftFunctional{:gga_c_pbe_sol}()
    β = 0.046  # Page 3, left column below figure 1
    γ = (1 - log(2)) / π^2
    PbeCorrelation(:gga_c_pbe_sol; β, γ)
end

# """
# APBE correlation.
# Constantin, Fabiano, Laricchia 2011 (DOI 10.1103/physrevlett.106.186406)
# """
function DftFunctional{:gga_c_apbe}()
    μ = 0.260   # p. 1, right column, bottom
    β = 3μ / π^2
    γ = (1 - log(2)) / π^2  # like in PBE
    PbeCorrelation(:gga_c_apbe; β, γ)
end

# """
# PBEmol correlation.
# del Campo, Gazqez, Trickey and others 2012 (DOI 10.1063/1.3691197)
# """
function DftFunctional{:gga_c_pbe_mol}()
    # β made to cancel self-interaction error in hydrogen
    β = 0.08384             # p. 4, right column, first paragraph
    γ = (1 - log(2)) / π^2  # like in PBE
    PbeCorrelation(:gga_c_pbe_mol; β, γ)
end

# """
# PBEfe correlation.
# Sarmiento-Perez, Silvana, Marques 2015 (DOI 10.1021/acs.jctc.5b00529)
# """
function DftFunctional{:gga_c_pbefe}()
    β = 0.043                    # Fitted constants, Table I
    γ = 0.031090690869654895034  # Fitted constants, Table I
    PbeCorrelation(:gga_c_pbefe; β, γ)
end
