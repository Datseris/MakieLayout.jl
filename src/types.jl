const BBox = Rect2D{Float32}

abstract type Side end

struct Left <: Side end
struct Right <: Side end
struct Top <: Side end
struct Bottom <: Side end

struct RowCols{T <: Union{Number, Vector{Float64}}}
    lefts::T
    rights::T
    tops::T
    bottoms::T
end

abstract type Alignable end

"""
Used to specify space that is occupied in a grid. Like 1:1|1:1 for the first square,
or 2:3|1:4 for a rect over the 2nd and 3rd row and the first four columns.
"""
struct Span
    rows::UnitRange{Int64}
    cols::UnitRange{Int64}
end

"""
An object that can be aligned that also specifies how much space it occupies in
a grid via its span.
"""
struct SpannedAlignable{T <: Alignable}
    al::T
    sp::Span
end

abstract type AlignMode end

struct Inside <: AlignMode end
struct Outside <: AlignMode
    padding::Tuple{Float32, Float32, Float32, Float32}
end
Outside() = Outside(0f0)
Outside(padding::Real) = Outside(Float32.(Tuple(padding for _ in 1:4)))
Outside(left::Real, right::Real, top::Real, bottom::Real) = Outside(Float32.((left, right, top, bottom)))

abstract type ContentSize end
abstract type GapSize <: ContentSize end

struct Auto <: ContentSize
    x::Float64 # ratio in case it's not determinable
end
Auto() = Auto(1)
struct Fixed <: GapSize
    x::Float64
end
struct Relative <: GapSize
    x::Float64
end
struct Aspect <: ContentSize
    index::Int
    ratio::Float64
end

mutable struct GridLayout <: Alignable
    parent::Union{Nothing, Scene, GridLayout}
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    rowsizes::Vector{ContentSize}
    colsizes::Vector{ContentSize}
    addedrowgaps::Vector{GapSize}
    addedcolgaps::Vector{GapSize}
    alignmode::AlignMode
    equalprotrusiongaps::Tuple{Bool, Bool}
    needs_update::Node{Bool}
    block_updates::Bool

    function GridLayout(
        parent, content, nrows, ncols, rowsizes, colsizes,
        addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update)

        if nrows < 1
            error("Number of rows can't be smaller than 1")
        end
        if ncols < 1
            error("Number of columns can't be smaller than 1")
        end

        if length(rowsizes) != nrows
            error("There are $nrows rows but $(length(rowsizes)) row sizes.")
        end
        if length(colsizes) != ncols
            error("There are $ncols columns but $(length(colsizes)) column sizes.")
        end
        if length(addedrowgaps) != nrows - 1
            error("There are $nrows rows but $(length(addedrowgaps)) row gaps.")
        end
        if length(addedcolgaps) != ncols - 1
            error("There are $ncols columns but $(length(addedcolgaps)) column gaps.")
        end

        g = new(parent, content, nrows, ncols, rowsizes, colsizes,
            addedrowgaps, addedcolgaps, alignmode, equalprotrusiongaps, needs_update, false)

        setup_updates!(g)

        g
    end
end

struct SolvedGridLayout <: Alignable
    bbox::BBox
    content::Vector{SpannedAlignable}
    nrows::Int
    ncols::Int
    grid::RowCols{Vector{Float64}}
end

struct SolvedProtrusionLayout{T} <: Alignable
    bbox::BBox
    content::T
end

struct AxisAspect
    aspect::Float32
end

struct DataAspect end

mutable struct ProtrusionLayout{T} <: Alignable
    parent::GridLayout
    protrusions::Union{Nothing, Node{Tuple{Float32, Float32, Float32, Float32}}}
    widthnode::Union{Nothing, Node{Float32}}
    heightnode::Union{Nothing, Node{Float32}}
    needs_update::Node{Bool}
    content::T
end

abstract type Ticks end

struct AutoLinearTicks <: Ticks
    idealtickdistance::Float32
end

struct ManualTicks <: Ticks
    values::Vector{Float32}
    labels::Vector{String}
end

mutable struct LayoutedAxis
    parent::Scene
    scene::Scene
    plots::Vector{AbstractPlot}
    xaxislinks::Vector{LayoutedAxis}
    yaxislinks::Vector{LayoutedAxis}
    bboxnode::Node{BBox}
    limits::Node{BBox}
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    needs_update::Node{Bool}
    attributes::Attributes
end

mutable struct LayoutedColorbar
    parent::Scene
    scene::Scene
    bboxnode::Node{BBox}
    limits::Node{Tuple{Float32, Float32}}
    protrusions::Node{Tuple{Float32, Float32, Float32, Float32}}
    needs_update::Node{Bool}
    attributes::Attributes
end

mutable struct LayoutedText
    parent::Scene
    bboxnode::Node{BBox}
    height::Node{Float32}
    width::Node{Float32}
    text::AbstractPlotting.Text
    attributes::Attributes
end

struct LayoutedSlider
    scene::Scene
    bboxnode::Node{BBox}
    height::Node{Float32}
    slider::Slider
end

struct LayoutedButton
    scene::Scene
    bboxnode::Node{BBox}
    width::Node{Float32}
    height::Node{Float32}
    button::Button
end