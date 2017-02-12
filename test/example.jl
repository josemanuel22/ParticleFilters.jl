using ParticleFilters
using Distributions
using StaticArrays
using Reel
using Plots

immutable DblIntegrator2D 
    W::Matrix{Float64} # Process noise covariance
    V::Matrix{Float64} # Observation noise covariance
    dt::Float64        # Time step
end
# state is [x, y, xdot, ydot];

# generates a new state from current state s and control a
function ParticleFilters.generate_s(model::DblIntegrator2D, s, a, rng::AbstractRNG)
    dt = model.dt
    A = [1.0 0.0 dt 0.0; 0.0 1.0 0.0 dt; 0.0 0.0 1.0 0.0; 0.0 0.0 0.0 1.0]
    B = [0.5*dt^2 0.0; 0.0 0.5*dt^2; dt 0.0; 0.0 dt]
    d = MvNormal(model.W)
    return A*s + B*a + rand(rng, d)
end

# returns the observation distribution for state sp (and action a)
function ParticleFilters.observation(model::DblIntegrator2D, a, sp)
    return MvNormal(sp[1:2], model.V)
end

N = 1000
model = DblIntegrator2D(0.001*eye(4), eye(2), 0.1)
rng = MersenneTwister(1)
filter = SIRParticleFilter(model, N, rng=rng)
b = ParticleCollection([4.0*rand(rng, 4)-2.0 for i in 1:N])
s = [0.0, 1.0, 1.0, 0.0]
film = roll(fps=10, duration=10) do t, dt
    global b, s; print(".")
    m = mean(b)
    a = [-m[1], -m[2]] # try to orbit the origin
    s = generate_s(model, s, a, rng)
    o = rand(rng, observation(model, a, s))
    b = update(filter, b, a, o)

    scatter([p[1] for p in particles(b)], [p[2] for p in particles(b)], color=:black, markersize=0.1, label="")
    scatter!([s[1]], [s[2]], color=:blue, xlim=(-5,5), ylim=(-5,5), title=t, label="")
end
write("particles.gif", film)