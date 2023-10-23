module TransitionLabels

    export transition_labels
    const transition_labels = [:send,:recv,:ell,:tau,:t] 

    export TransitionLabel
    struct TransitionLabel

        "Returns a string label of the transition"
        function TransitionLabel(kind::Symbol,args...)

            # if concat transitions?
            if kind==:concat
                # TODO, separate into list of transition labels

            else
                @assert kind ∈ transition_labels "TransitionLabel, unsupported kind: $(string(kind))."

            end
            
        end

    end

end