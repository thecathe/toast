module DemoTOAST

    include("toast.jl")
    using .TOAST

    export example_types
    
    example_types = Array{SessionType}([])

    exa_a = Interact(:send, ("a"), δ(:eq,"x",2), λ("x"),
        Interact(:recv, ("b"), δ(:eq,"x",2),λ(), End()))
    push!(example_types, exa_a)

    exa_b = μ("z", Interact(exa_a,α("z")))
    push!(example_types, exa_b)

    exa_c = Interact(:recv, ("start"), δ(), λ("x"),
        μ("z", Choice([
            Interact(:send, ("a"), δ(:eq,"x",2), λ("x"),
                Interact(:recv, ("b",String), δ(:eq,"x",2), λ(), End())),
            Interact(:send, ("c"), δ(:not,δ(:geq,"y",2)), λ("y"),
                Interact(:recv, ("d",String), δ(:geq,"x",2), λ(), End())),
            # Interact(:recv, ("e"), δ(:and,δ(:not,δ(:geq,"x",5)),δ(:geq,"x",3)), λ("y"),
            #     Interact(:send, ("f",String), δ(:eq,"y",2),λ(), End())),
            Interact(:recv, ("e"), δ(:geq,"x",2), λ("y"),
                Interact(:send, ("f",String), δ(:eq,"y",0), λ(), α("z")))
        ]))
    )
    push!(example_types, exa_c)

end