const Choice = Int8
const Percept = Int8 #Int8 to save memory?
const PerceptSequence = Vector{Percept}
const TaggedPercept = Tuple{Symbol, Int8}
const TaggedPerceptSequence = Vector{TaggedPercept}


# abstract type Agent end

"""
    Agent

Basic Agent type. Agents are nodes of the AgentGraph and are players in games.
"""
mutable struct Agent
    name::String
    is_hermit::Bool
    memory::PerceptSequence
    rational_choice::Choice
    choice::Choice

    function Agent(name::String, is_hermit::Bool, memory::PerceptSequence, rational_choice::Choice, choice::Choice) #initialize choice at 0 (representing no choice)
        return new(name, is_hermit, memory, rational_choice, choice)
    end
    function Agent(name::String, memory::PerceptSequence, rational_choice::Choice, choice::Choice) #initialize choice at 0 (representing no choice)
        return new(name, false, memory, rational_choice, choice)
    end
    function Agent(name::String, is_hermit::Bool)
        return new(name, is_hermit, PerceptSequence([]), Choice(0), Choice(0))
    end
    function Agent(name::String)
        return new(name, false, PerceptSequence([]), Choice(0), Choice(0))
    end
    function Agent()
        return new("", false, PerceptSequence([]), Choice(0), Choice(0))
    end
end


##########################################
# Agent Accessors
##########################################

"""
    displayname(agent::Agent)

Get the name/identifier of an agent.
"""
displayname(agent::Agent) = getfield(agent, :name)

"""
    ishermit(agent::Agent)

Determine if an agent is a hermit on the AgentGraph (i.e. degree=0).
"""
ishermit(agent::Agent) = getfield(agent, :is_hermit)

"""
    Interactions.ishermit!(agent::Agent)

Set an agent's hermit status on the AgentGraph (i.e. degree=0).
"""
ishermit!(agent::Agent, is_hermit::Bool) = setfield!(agent, :is_hermit, is_hermit)

"""
    memory(agent::Agent)

Get the current memory of an agent.
"""
memory(agent::Agent) = getfield(agent, :memory)

"""
    rational_choice(agent::Agent)

Get an agent's most recent 'rational' choice (i.e. no error).
"""
rational_choice(agent::Agent) = getfield(agent, :rational_choice)

"""
    rational_choice!(agent::Agent)

Set an agent's 'rational' choice.
"""
rational_choice!(agent::Agent, choice::Integer) = setfield!(agent, :rational_choice, Choice(choice))


"""
    choice(agent::Agent)

Get an agent's most recent actual choice.
"""
choice(agent::Agent) = getfield(agent, :choice)

"""
    choice!(agent::Agent)

Set an agent's choice.
"""
choice!(agent::Agent, choice::Integer) = setfield!(agent, :choice, Choice(choice))


# mutable struct TaggedAgent #could make a TaggedAgent as well to separate tags
#     name::String
#     tag::Union{Symbol} #NOTE: REMOVE
#     is_hermit::Bool
#     wealth::Int #is this necessary? #NOTE: REMOVE
#     memory::PerceptSequence
#     choice::Int8

#     function Agent(name::String, wealth::Int, memory::Vector{Tuple{Symbol, Int8}}, tag::Union{Nothing, Symbol} = nothing, choice::Int8 = Int8(0)) #initialize choice at 0 (representing no choice)
#         return new(name, tag, false, wealth, memory, choice)
#     end
#     function Agent(name::String, tag::Union{Nothing, Symbol} = nothing)
#         return new(name, tag, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String, is_hermit::Bool)
#         return new(name, nothing, is_hermit, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent(name::String)
#         return new(name, nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
#     function Agent()
#         return new("", nothing, false, 0, Vector{Tuple{Symbol, Int8}}([]), Int8(0))
#     end
# end