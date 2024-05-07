### A Pluto.jl notebook ###
# v0.19.41

using Markdown
using InteractiveUtils

# ╔═╡ 94454d67-ebc8-4e0c-9108-a343b4688d27
using Test

# ╔═╡ 92116900-375d-4182-ae95-2a2024af7c36
include("toast.jl")

# ╔═╡ ed31fe6d-b481-45f9-bc22-de4277ad48a5
using .TOAST

# ╔═╡ 30df22d6-f325-44ab-933f-4658cb330e0f
@info show(ν([("a",2)]))
@info show(ResetClocks!(ν([("a",2)]),"a"))
@info show(ResetClocks!(ν([("a",2)]),"a"))
reset_a_to_0 = ν([("a",2)])
ResetClocks!(reset_a_to_0)
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
# ╠═92116900-375d-4182-ae95-2a2024af7c36
# ╠═ed31fe6d-b481-45f9-bc22-de4277ad48a5
# ╠═30df22d6-f325-44ab-933f-4658cb330e0f
# ╠═58e08598-f500-4ebe-857b-0e59790a4266
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
