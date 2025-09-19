const Choice = Int8
const Percept = Int8 #NOTE: change to Int
const PerceptSequence = Vector{Percept}
const TaggedPercept = Tuple{Symbol, Int8}
const TaggedPerceptSequence = Vector{TaggedPercept}


abstract type AbstractAgent end

"""
    Agent

Basic Agent type. Agents are nodes of the AgentGraph and are players in games.
"""
mutable struct Agent <: AbstractAgent
    id::Int
    is_hermit::Bool
    memory::PerceptSequence
    rational_choice::Choice
    choice::Choice

    function Agent(id::Int, is_hermit::Bool, memory::Vector{<:Integer}, rational_choice::Integer, choice::Integer) #NOTE: do i need this method? (currently required for structtypes)
        return new(id, is_hermit, memory, rational_choice, choice)
    end
    function Agent(;id::Int=0, is_hermit::Bool=false, memory::Vector{<:Integer}=PerceptSequence([]), rational_choice::Integer=Choice(0), choice::Integer=Choice(0))
        return new(id, is_hermit, memory, rational_choice, choice)
    end
end


##########################################
# Agent Accessors
##########################################

"""
    id(agent::Agent)

Get the id of an agent.
"""
id(agent::Agent) = getfield(agent, :id)

"""
    displayname(agent::Agent)

Get the id/identifier of an agent.
"""
displayname(agent::Agent) = string(getfield(agent, :id)) #NOTE: is this unnecessary?

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

# """
#     memory_length(agent::Agent)

# Get the memory length of an agent.
# """
# memory_length(agent::Agent) = length(memory(agent))

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