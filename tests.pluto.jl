### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ 94454d67-ebc8-4e0c-9108-a343b4688d27
using Test

# ╔═╡ 54d94657-a8c1-4ba0-bedc-1e168f9cf538
function ingredients(path::String)
	# this is from the Julia source code (evalfile in base/loading.jl)
	# but with the modification that it returns the module instead of the last object
	name = Symbol(basename(path))
	m = Module(name)
	Core.eval(m,
        Expr(:toplevel,
             :(eval(x) = $(Expr(:core, :eval))($name, x)),
             :(include(x) = $(Expr(:top, :include))($name, x)),
             :(include(mapexpr::Function, x) = $(Expr(:top, :include))(mapexpr, $name, x)),
             :(include($path))))
	m
end

# ╔═╡ 71f47c0f-60ff-4769-b0a1-a539b019b16c
begin
	# include("toast.jl")
	# using .TOAST
	toast = ingredients("toast.jl").TOAST
	using .toast
	
	# clocks and constraints
	export Num
    export Clock, λ
    export ν, ValueOf!, ResetClocks!, TimeStep!
    export δ, supported_constraints
    export δExpr, normaliseδ, DBC, δBounds
    export δ⬇, δEvaluation!

	# session types and actions
    export End, μ, α, Interact, Choice
    export Msgs, Msg, Payload, Del
    export Actions, Action
    export SessionType, S
    export Duality, dual

	# configurations and evaluation of enabled actions
    export Local, Social, System
    export Queue, head!
    export Evaluate!

	# operational semantics of configurations
    export Transition!
    export Tick!, Act!, Unfold!
    export Que!, Send!, Recv!, Time!
    export Wait!, Par!, Com!

	# well-formedness rules
end

# ╔═╡ 4b136447-4dea-4fc8-a904-d4ccb1a3fde4


# ╔═╡ 0e91cf66-4845-4736-be13-62a87f234159
# clock valuation tests
# init with a=2
clock_valuations_a_2 = toast.ν([("a",2)])

# ╔═╡ 874119de-da2e-47db-b883-41821aa4fb62
@info string(clock_valuations_a_2)

# ╔═╡ 14a02540-ed5d-4b0d-ba76-de74ab763002
@test toast.ValueOf!(clock_valuations_a_2, "a").value==2

# ╔═╡ 70e3ef84-0349-48d2-8d47-97862f868a7d
@test toast.ValueOf!(clock_valuations_a_2, "b").value==0

# ╔═╡ 7a34639f-d7b8-4504-860d-0e25d8340ae4
@info string(clock_valuations_a_2)

# ╔═╡ 1602a986-05c3-4f7e-9eef-40e3ea817344
# reset a->0
toast.ResetClocks!(clock_valuations_a_2,"a")

# ╔═╡ 0f55676f-e446-4fb2-9fd7-07241efaddc4
@test toast.ValueOf!(clock_valuations_a_2, "a").value==0

# ╔═╡ e8399502-f8c0-4494-8197-6480b27c99af
@test toast.ValueOf!(clock_valuations_a_2, "b").value==0

# ╔═╡ d5b05f50-11c6-4204-b862-0006a8d48635
# time step 1
toast.TimeStep!(clock_valuations_a_2,1)

# ╔═╡ b1269f2c-73d8-445b-8968-36bfca0a6fac
@test toast.ValueOf!(clock_valuations_a_2, "a").value==1

# ╔═╡ d44010b8-ed19-4606-9f11-743127ac4e8e
@test toast.ValueOf!(clock_valuations_a_2, "b").value==1

# ╔═╡ 06ecc56e-f5cb-4c21-b150-d53e77af3425
@test toast.ValueOf!(clock_valuations_a_2, "c").value==1

	# reset a->0

# ╔═╡ 31ce580b-4e75-484a-a969-7a3fe1f6ac4a
toast.ResetClocks!(clock_valuations_a_2,"a")

# ╔═╡ eec8cb94-cab9-4049-9a80-c9190555b903
@test toast.ValueOf!(clock_valuations_a_2, "a").value==0

# ╔═╡ cae8b31e-7513-4589-8edc-c3f11c735be5
@test toast.ValueOf!(clock_valuations_a_2, "b").value==1

# ╔═╡ bfac35e4-448d-445f-9757-2f797d2f7020
@test toast.ValueOf!(clock_valuations_a_2, "c").value==1
	
	# time step 2

# ╔═╡ c090b19e-14a5-45c7-b7e1-8708c7298b8e
toast.TimeStep!(clock_valuations_a_2,2)

# ╔═╡ da4d8d05-eaae-43c4-b293-b0fe317e6a6b
@test toast.ValueOf!(clock_valuations_a_2, "a").value==2

# ╔═╡ daf06cdc-d622-4d1f-94c6-dde1d71bb2ab
@test toast.ValueOf!(clock_valuations_a_2, "b").value==3

# ╔═╡ 32ecb863-f3e8-4e86-ac02-597749b02010
@test toast.ValueOf!(clock_valuations_a_2, "c").value==3

# ╔═╡ 3ef6954a-a44e-4361-a244-a4a5d033c413
@test toast.ValueOf!(clock_valuations_a_2, "d").value==3
	
	# reset {a,c}->0

# ╔═╡ dcedbbe2-5b96-4517-aa03-4653fe28f667
toast.ResetClocks!(clock_valuations_a_2,["a","c"])

# ╔═╡ ff5e2784-e39a-4043-8ab6-7189c743f872
@test toast.ValueOf!(clock_valuations_a_2, "a").value==0

# ╔═╡ d9233c5a-34dc-4838-81dd-a42f0f3b0e6a
@test toast.ValueOf!(clock_valuations_a_2, "b").value==3

# ╔═╡ 837d5485-9e94-4304-bc0d-61006b74493f
@test toast.ValueOf!(clock_valuations_a_2, "c").value==0

# ╔═╡ a683d295-30d4-4bdb-9629-94eeb2d77ba3
@test toast.ValueOf!(clock_valuations_a_2, "d").value==3
	
	# time step 3

# ╔═╡ 6bd02c02-82ff-4bae-b178-52e764ab23b3
toast.TimeStep!(clock_valuations_a_2,3)

# ╔═╡ 60f4ce04-3a4b-47be-9ffd-14445ab521c4
@test toast.ValueOf!(clock_valuations_a_2, "a").value==3

# ╔═╡ dbb34170-b56d-4fa9-8d73-e96d471b3c34
@test toast.ValueOf!(clock_valuations_a_2, "b").value==6

# ╔═╡ afdd3b64-a946-48af-bfca-5653dfdc6cee
@test toast.ValueOf!(clock_valuations_a_2, "c").value==3

# ╔═╡ a0c7106f-b28c-424c-ad3f-81e7e97690fd
@test toast.ValueOf!(clock_valuations_a_2, "d").value==6
	
	# reset all

# ╔═╡ 6a193378-32ec-420f-a431-02c4dc4a15bf
toast.ResetClocks!(clock_valuations_a_2)

# ╔═╡ d9274b67-9102-4aa3-a74a-36923939e368
@test toast.ValueOf!(clock_valuations_a_2, "a").value==0

# ╔═╡ c8c2b767-cacc-4b8e-a0db-bc0400706acd
@test toast.ValueOf!(clock_valuations_a_2, "b").value==0

# ╔═╡ 85ef351a-7d2a-4611-859b-896735942786
@test toast.ValueOf!(clock_valuations_a_2, "c").value==0

# ╔═╡ 4499ac2d-a192-4ce7-940f-fbaea6c8e2c0
@test toast.ValueOf!(clock_valuations_a_2, "d").value==0

# ╔═╡ 2f778586-fb28-4759-ba9d-99b3c52470fa
@test toast.ValueOf!(clock_valuations_a_2, "e").value==6
	
# end

# ╔═╡ 4081a160-afb9-4beb-9736-de61eb26f500
@info 

# ╔═╡ aab0bd2b-f7d0-4d01-8ab4-a4333a92218a
@info show(ResetClocks!(ν([("a",2)]),"a"))

# ╔═╡ 2eaa4b74-6fa2-41fb-8ee3-ffeff772d576
reset_a_to_0 = ν([("a",2)])

# ╔═╡ 7571593d-6c1f-4dcc-8de7-0bc8e96005b5
ResetClocks!(reset_a_to_0)

# ╔═╡ f088a34c-5424-464e-8af6-61a4c75fd64f
@info show(ValueOf!(reset_a_to_0,"a"))

# ╔═╡ 58e08598-f500-4ebe-857b-0e59790a4266
# @test ValueOf!(TimeStep!(ν([("a",2)]),1),"a")==3

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Test = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.3"
manifest_format = "2.0"
project_hash = "71d91126b5a1fb1020e1098d9d492de2a4438fd2"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"
"""

# ╔═╡ Cell order:
# ╠═94454d67-ebc8-4e0c-9108-a343b4688d27
# ╠═54d94657-a8c1-4ba0-bedc-1e168f9cf538
# ╠═4b136447-4dea-4fc8-a904-d4ccb1a3fde4
# ╠═71f47c0f-60ff-4769-b0a1-a539b019b16c
# ╠═0e91cf66-4845-4736-be13-62a87f234159
# ╠═874119de-da2e-47db-b883-41821aa4fb62
# ╠═14a02540-ed5d-4b0d-ba76-de74ab763002
# ╠═70e3ef84-0349-48d2-8d47-97862f868a7d
# ╠═7a34639f-d7b8-4504-860d-0e25d8340ae4
# ╠═1602a986-05c3-4f7e-9eef-40e3ea817344
# ╠═0f55676f-e446-4fb2-9fd7-07241efaddc4
# ╠═e8399502-f8c0-4494-8197-6480b27c99af
# ╠═d5b05f50-11c6-4204-b862-0006a8d48635
# ╠═b1269f2c-73d8-445b-8968-36bfca0a6fac
# ╠═d44010b8-ed19-4606-9f11-743127ac4e8e
# ╠═06ecc56e-f5cb-4c21-b150-d53e77af3425
# ╠═31ce580b-4e75-484a-a969-7a3fe1f6ac4a
# ╠═eec8cb94-cab9-4049-9a80-c9190555b903
# ╠═cae8b31e-7513-4589-8edc-c3f11c735be5
# ╠═bfac35e4-448d-445f-9757-2f797d2f7020
# ╠═c090b19e-14a5-45c7-b7e1-8708c7298b8e
# ╠═da4d8d05-eaae-43c4-b293-b0fe317e6a6b
# ╠═daf06cdc-d622-4d1f-94c6-dde1d71bb2ab
# ╠═32ecb863-f3e8-4e86-ac02-597749b02010
# ╠═3ef6954a-a44e-4361-a244-a4a5d033c413
# ╠═dcedbbe2-5b96-4517-aa03-4653fe28f667
# ╠═ff5e2784-e39a-4043-8ab6-7189c743f872
# ╠═d9233c5a-34dc-4838-81dd-a42f0f3b0e6a
# ╠═837d5485-9e94-4304-bc0d-61006b74493f
# ╠═a683d295-30d4-4bdb-9629-94eeb2d77ba3
# ╠═6bd02c02-82ff-4bae-b178-52e764ab23b3
# ╠═60f4ce04-3a4b-47be-9ffd-14445ab521c4
# ╠═dbb34170-b56d-4fa9-8d73-e96d471b3c34
# ╠═afdd3b64-a946-48af-bfca-5653dfdc6cee
# ╠═a0c7106f-b28c-424c-ad3f-81e7e97690fd
# ╠═6a193378-32ec-420f-a431-02c4dc4a15bf
# ╠═d9274b67-9102-4aa3-a74a-36923939e368
# ╠═c8c2b767-cacc-4b8e-a0db-bc0400706acd
# ╠═85ef351a-7d2a-4611-859b-896735942786
# ╠═4499ac2d-a192-4ce7-940f-fbaea6c8e2c0
# ╠═2f778586-fb28-4759-ba9d-99b3c52470fa
# ╠═4081a160-afb9-4beb-9736-de61eb26f500
# ╠═aab0bd2b-f7d0-4d01-8ab4-a4333a92218a
# ╠═2eaa4b74-6fa2-41fb-8ee3-ffeff772d576
# ╠═7571593d-6c1f-4dcc-8de7-0bc8e96005b5
# ╠═f088a34c-5424-464e-8af6-61a4c75fd64f
# ╠═58e08598-f500-4ebe-857b-0e59790a4266
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
